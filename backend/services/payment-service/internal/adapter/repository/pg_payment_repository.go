package repository

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/payment-service/internal/domain/enum"
	"kz/inflap/backend/services/payment-service/internal/domain/model"
	"kz/inflap/backend/services/payment-service/internal/domain/port"
)

type PGPaymentRepository struct {
	pool *pgxpool.Pool
}

func NewPGPaymentRepository(pool *pgxpool.Pool) *PGPaymentRepository {
	return &PGPaymentRepository{pool: pool}
}

type PGPaymentTxRepository struct {
	tx pgx.Tx
}

const paymentSelectColumns = `
	id, idempotency_key,
	subject_type, subject_id, purpose,
	payer_user_id, requested_by_user_id,
	operation_type, status, provider,
	provider_transaction_id, parent_transaction_id,
	amount_minor, currency, description, metadata,
	failure_code, failure_message, completed_at,
	created_at, updated_at
`

func (r *PGPaymentRepository) WithTx(ctx context.Context, fn func(repo port.PaymentTxRepository) error) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin payment tx: %w", err)
	}

	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err = fn(&PGPaymentTxRepository{tx: tx}); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit payment tx: %w", err)
	}

	return nil
}

func (r *PGPaymentRepository) GetTransactionByID(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error) {
	const query = `
		SELECT
	` + paymentSelectColumns + `
		FROM payment_transactions
		WHERE id = $1
		LIMIT 1
	`

	item, err := scanPaymentTransaction(r.pool.QueryRow(ctx, query, transactionID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get payment transaction by id: %w", err)
	}

	return item, nil
}

func (r *PGPaymentRepository) GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error) {
	const query = `
		SELECT
	` + paymentSelectColumns + `
		FROM payment_transactions
		WHERE idempotency_key = $1
		LIMIT 1
	`

	item, err := scanPaymentTransaction(r.pool.QueryRow(ctx, query, strings.TrimSpace(idempotencyKey)))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get payment transaction by idempotency key: %w", err)
	}

	return item, nil
}

func (r *PGPaymentRepository) ListTransactions(ctx context.Context, filter port.PaymentFilter) ([]*model.PaymentTransaction, error) {
	base := `
		SELECT
	` + paymentSelectColumns + `
		FROM payment_transactions
		WHERE 1 = 1
	`

	parts := []string{base}
	args := make([]any, 0, 8)
	argPos := 1

	if filter.SubjectType != nil && strings.TrimSpace(*filter.SubjectType) != "" {
		parts = append(parts, fmt.Sprintf(" AND subject_type = $%d", argPos))
		args = append(args, model.NormalizePaymentCode(*filter.SubjectType))
		argPos++
	}
	if filter.SubjectID != nil {
		parts = append(parts, fmt.Sprintf(" AND subject_id = $%d", argPos))
		args = append(args, *filter.SubjectID)
		argPos++
	}
	if filter.PayerUserID != nil {
		parts = append(parts, fmt.Sprintf(" AND payer_user_id = $%d", argPos))
		args = append(args, *filter.PayerUserID)
		argPos++
	}
	if filter.OperationType != nil {
		parts = append(parts, fmt.Sprintf(" AND operation_type = $%d", argPos))
		args = append(args, string(*filter.OperationType))
		argPos++
	}
	if filter.Status != nil {
		parts = append(parts, fmt.Sprintf(" AND status = $%d", argPos))
		args = append(args, string(*filter.Status))
		argPos++
	}

	parts = append(parts, " ORDER BY created_at DESC, id DESC")
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, fmt.Errorf("list payment transactions: %w", err)
	}
	defer rows.Close()

	result := make([]*model.PaymentTransaction, 0)
	for rows.Next() {
		item, scanErr := scanPaymentTransaction(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan listed payment transaction: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGPaymentTxRepository) GetTransactionByIDForUpdate(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error) {
	const query = `
		SELECT
	` + paymentSelectColumns + `
		FROM payment_transactions
		WHERE id = $1
		LIMIT 1
		FOR UPDATE
	`

	item, err := scanPaymentTransaction(r.tx.QueryRow(ctx, query, transactionID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get payment transaction by id for update: %w", err)
	}

	return item, nil
}

func (r *PGPaymentTxRepository) GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error) {
	const query = `
		SELECT
	` + paymentSelectColumns + `
		FROM payment_transactions
		WHERE idempotency_key = $1
		LIMIT 1
		FOR UPDATE
	`

	item, err := scanPaymentTransaction(r.tx.QueryRow(ctx, query, strings.TrimSpace(idempotencyKey)))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get payment transaction by idempotency key for update: %w", err)
	}

	return item, nil
}

func (r *PGPaymentTxRepository) SumReservedChildAmount(
	ctx context.Context,
	parentTransactionID uuid.UUID,
	operationType enum.PaymentOperationType,
) (int64, error) {
	const query = `
		SELECT COALESCE(SUM(amount_minor), 0)
		FROM payment_transactions
		WHERE parent_transaction_id = $1
		  AND operation_type = $2
		  AND status IN ($3, $4)
	`

	var amount int64
	if err := r.tx.QueryRow(
		ctx,
		query,
		parentTransactionID,
		string(operationType),
		string(enum.PaymentStatusPending),
		string(enum.PaymentStatusSucceeded),
	).Scan(&amount); err != nil {
		return 0, fmt.Errorf("sum reserved child payment amount: %w", err)
	}

	return amount, nil
}

func (r *PGPaymentTxRepository) CreateTransaction(ctx context.Context, item *model.PaymentTransaction) error {
	const query = `
		INSERT INTO payment_transactions (
			id, idempotency_key,
			subject_type, subject_id, purpose,
			payer_user_id, requested_by_user_id,
			operation_type, status, provider,
			provider_transaction_id, parent_transaction_id,
			amount_minor, currency, description, metadata,
			failure_code, failure_message, completed_at,
			created_at, updated_at
		) VALUES (
			$1, $2,
			$3, $4, $5,
			$6, $7,
			$8, $9, $10,
			$11, $12,
			$13, $14, $15, $16::jsonb,
			$17, $18, $19,
			$20, $21
		)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.IdempotencyKey,
		item.SubjectType,
		item.SubjectID,
		item.Purpose,
		item.PayerUserID,
		item.RequestedByUserID,
		string(item.OperationType),
		string(item.Status),
		string(item.Provider),
		item.ProviderTransactionID,
		item.ParentTransactionID,
		item.AmountMinor,
		item.Currency,
		item.Description,
		string(item.Metadata),
		item.FailureCode,
		item.FailureMessage,
		item.CompletedAt,
		item.CreatedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert payment transaction: %w", err)
	}

	return nil
}

func (r *PGPaymentTxRepository) UpdateTransactionResult(ctx context.Context, item *model.PaymentTransaction) error {
	const query = `
		UPDATE payment_transactions
		SET
			status = $2,
			provider = $3,
			provider_transaction_id = $4,
			failure_code = $5,
			failure_message = $6,
			completed_at = $7,
			updated_at = $8
		WHERE id = $1
	`

	if err := item.Validate(); err != nil {
		return err
	}

	tag, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		string(item.Status),
		string(item.Provider),
		item.ProviderTransactionID,
		item.FailureCode,
		item.FailureMessage,
		item.CompletedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update payment transaction result: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}

	return nil
}

func (r *PGPaymentTxRepository) CreateEvent(ctx context.Context, item *model.PaymentEvent) error {
	const query = `
		INSERT INTO payment_events (
			id, transaction_id, event_type, payload, created_at
		) VALUES ($1, $2, $3, $4::jsonb, $5)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.TransactionID,
		item.EventType,
		string(item.Payload),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert payment event: %w", err)
	}

	return nil
}

type paymentScanner interface {
	Scan(dest ...any) error
}

func scanPaymentTransaction(row paymentScanner) (*model.PaymentTransaction, error) {
	var (
		item model.PaymentTransaction

		operationRaw string
		statusRaw    string
		providerRaw  string
	)

	err := row.Scan(
		&item.ID,
		&item.IdempotencyKey,
		&item.SubjectType,
		&item.SubjectID,
		&item.Purpose,
		&item.PayerUserID,
		&item.RequestedByUserID,
		&operationRaw,
		&statusRaw,
		&providerRaw,
		&item.ProviderTransactionID,
		&item.ParentTransactionID,
		&item.AmountMinor,
		&item.Currency,
		&item.Description,
		&item.Metadata,
		&item.FailureCode,
		&item.FailureMessage,
		&item.CompletedAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	item.OperationType = enum.PaymentOperationType(operationRaw)
	item.Status = enum.PaymentStatus(statusRaw)
	item.Provider = enum.PaymentProvider(providerRaw)

	return &item, nil
}
