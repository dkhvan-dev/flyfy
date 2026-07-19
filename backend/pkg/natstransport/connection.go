package natstransport

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"net"
	"strings"
	"time"

	"github.com/nats-io/nats.go"
)

type Hooks struct {
	Disconnected func(error)
	Reconnected  func()
	Closed       func(error)
	AsyncError   func(error)
}

type ErrorCode string

const (
	ErrorTimeout        ErrorCode = "timeout"
	ErrorAuthentication ErrorCode = "authentication"
	ErrorTLS            ErrorCode = "tls"
	ErrorUnavailable    ErrorCode = "unavailable"
	ErrorClosed         ErrorCode = "closed"
	ErrorTransport      ErrorCode = "transport"
)

// Error deliberately does not retain or unwrap the source error because NATS
// errors may contain endpoint credentials or mounted secret paths.
type Error struct {
	operation string
	code      ErrorCode
}

func (e *Error) Error() string {
	if e == nil {
		return "NATS transport failed"
	}
	return fmt.Sprintf("NATS %s failed (%s)", e.operation, e.code)
}

func (e *Error) String() string {
	return e.Error()
}

func (e *Error) GoString() string {
	return e.Error()
}

func (e *Error) Code() ErrorCode {
	if e == nil {
		return ErrorTransport
	}
	return e.code
}

func Connect(config Config, clientName string, hooks Hooks) (*nats.Conn, error) {
	if strings.TrimSpace(clientName) == "" {
		return nil, errors.New("NATS client name is required")
	}
	prepared, err := config.prepare()
	if err != nil {
		return nil, err
	}
	options := connectionOptions(config, prepared, strings.TrimSpace(clientName), hooks)
	connection, err := nats.Connect(strings.Join(prepared.endpoints, ","), options...)
	if err != nil {
		return nil, sanitizeError("connect", err)
	}
	return connection, nil
}

func Drain(connection *nats.Conn) error {
	if connection == nil {
		return nil
	}
	if err := connection.Drain(); err != nil {
		return sanitizeError("drain", err)
	}
	return nil
}

func connectionOptions(config Config, prepared preparedConfig, clientName string, hooks Hooks) []nats.Option {
	options := []nats.Option{
		nats.Name(clientName),
		nats.Timeout(config.ConnectTimeout),
		nats.RetryOnFailedConnect(true),
		nats.MaxReconnects(config.MaxReconnects),
		nats.ReconnectWait(config.ReconnectWait),
		nats.ReconnectJitter(100*time.Millisecond, 500*time.Millisecond),
		nats.ReconnectBufSize(1024 * 1024),
		nats.PingInterval(config.PingInterval),
		nats.MaxPingsOutstanding(config.MaxPingsOut),
		nats.DrainTimeout(config.DrainTimeout),
		nats.DisconnectErrHandler(func(_ *nats.Conn, err error) {
			if hooks.Disconnected != nil {
				hooks.Disconnected(sanitizeError("disconnect", err))
			}
		}),
		nats.ReconnectHandler(func(_ *nats.Conn) {
			if hooks.Reconnected != nil {
				hooks.Reconnected()
			}
		}),
		nats.ClosedHandler(func(connection *nats.Conn) {
			if hooks.Closed != nil {
				hooks.Closed(sanitizeError("close", connection.LastError()))
			}
		}),
		nats.ErrorHandler(func(_ *nats.Conn, _ *nats.Subscription, err error) {
			if hooks.AsyncError != nil {
				hooks.AsyncError(sanitizeError("async", err))
			}
		}),
	}
	if prepared.secure {
		options = append(options,
			nats.Secure(prepared.tls),
			nats.UserCredentials(config.CredentialsPath),
		)
	}
	return options
}

func sanitizeError(operation string, err error) error {
	if err == nil {
		return nil
	}
	code := ErrorTransport
	var netError net.Error
	var certificateError *tls.CertificateVerificationError
	var unknownAuthority x509.UnknownAuthorityError
	switch {
	case errors.Is(err, context.DeadlineExceeded), errors.Is(err, nats.ErrTimeout):
		code = ErrorTimeout
	case errors.Is(err, nats.ErrAuthorization), errors.Is(err, nats.ErrAuthExpired),
		errors.Is(err, nats.ErrAuthRevoked), errors.Is(err, nats.ErrAccountAuthExpired):
		code = ErrorAuthentication
	case errors.As(err, &certificateError), errors.As(err, &unknownAuthority):
		code = ErrorTLS
	case errors.Is(err, nats.ErrNoServers), errors.Is(err, nats.ErrDisconnected):
		code = ErrorUnavailable
	case errors.Is(err, nats.ErrConnectionClosed), errors.Is(err, nats.ErrConnectionDraining):
		code = ErrorClosed
	case errors.As(err, &netError) && netError.Timeout():
		code = ErrorTimeout
	}
	return &Error{operation: sanitizeOperation(operation), code: code}
}

func sanitizeOperation(operation string) string {
	switch operation {
	case "connect", "disconnect", "close", "async", "drain":
		return operation
	default:
		return "transport"
	}
}
