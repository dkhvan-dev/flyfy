create table if not exists platform_personal_data_policy_state (
    singleton_id smallint primary key not null default 1,
    revision bigint not null,
    state varchar(16) not null,
    issued_at timestamptz not null,
    valid_until timestamptz not null,
    changed_at timestamptz not null,
    actor varchar(200) not null,
    reason varchar(1000) not null,
    change_ticket varchar(200) not null,
    constraint ck_platform_personal_data_policy_singleton check (singleton_id = 1),
    constraint ck_platform_personal_data_policy_revision check (revision > 0),
    constraint ck_platform_personal_data_policy_state check (state in ('AVAILABLE', 'LOCKED')),
    constraint ck_platform_personal_data_policy_window check (
        valid_until > issued_at
        and valid_until <= issued_at + interval '30 seconds'
    ),
    constraint ck_platform_personal_data_policy_actor check (
        actor = btrim(actor)
        and char_length(actor) between 1 and 200
        and actor !~ '[[:cntrl:]]'
    ),
    constraint ck_platform_personal_data_policy_reason check (
        reason = btrim(reason)
        and char_length(reason) between 1 and 1000
        and reason !~ '[[:cntrl:]]'
    ),
    constraint ck_platform_personal_data_policy_ticket check (
        change_ticket = btrim(change_ticket)
        and char_length(change_ticket) between 1 and 200
        and change_ticket !~ '[[:cntrl:]]'
    )
);

create table if not exists platform_personal_data_policy_history (
    id bigint generated always as identity primary key not null,
    revision bigint unique not null,
    previous_revision bigint,
    previous_state varchar(16),
    state varchar(16) not null,
    issued_at timestamptz not null,
    valid_until timestamptz not null,
    changed_at timestamptz not null,
    actor varchar(200) not null,
    reason varchar(1000) not null,
    change_ticket varchar(200) not null,
    constraint ck_platform_personal_data_policy_history_revision check (revision > 0),
    constraint ck_platform_personal_data_policy_history_state check (state in ('AVAILABLE', 'LOCKED')),
    constraint ck_platform_personal_data_policy_history_previous check (
        (
            revision = 1
            and previous_revision is null
            and previous_state is null
        )
        or (
            previous_revision is not null
            and previous_revision > 0
            and previous_revision < revision
            and previous_state in ('AVAILABLE', 'LOCKED')
        )
    ),
    constraint ck_platform_personal_data_policy_history_window check (
        valid_until > issued_at
        and valid_until <= issued_at + interval '30 seconds'
    ),
    constraint ck_platform_personal_data_policy_history_actor check (
        actor = btrim(actor)
        and char_length(actor) between 1 and 200
        and actor !~ '[[:cntrl:]]'
    ),
    constraint ck_platform_personal_data_policy_history_reason check (
        reason = btrim(reason)
        and char_length(reason) between 1 and 1000
        and reason !~ '[[:cntrl:]]'
    ),
    constraint ck_platform_personal_data_policy_history_ticket check (
        change_ticket = btrim(change_ticket)
        and char_length(change_ticket) between 1 and 200
        and change_ticket !~ '[[:cntrl:]]'
    )
);

comment on column platform_personal_data_policy_state.revision is
    'Monotonic decision revision incremented by both lease renewal and administrative state transition';
comment on table platform_personal_data_policy_history is
    'Append-only administrative state transitions; lease-only revision increments are intentionally omitted';

create index if not exists idx_platform_personal_data_policy_history_changed_at
    on platform_personal_data_policy_history(changed_at desc, id desc);

create index if not exists idx_platform_personal_data_policy_history_state
    on platform_personal_data_policy_history(state, changed_at desc, id desc);

with seed as (
    select clock_timestamp() as issued_at
)
insert into platform_personal_data_policy_state (
    singleton_id,
    revision,
    state,
    issued_at,
    valid_until,
    changed_at,
    actor,
    reason,
    change_ticket
)
select
    1,
    1,
    'AVAILABLE',
    issued_at,
    issued_at + interval '20 seconds',
    issued_at,
    'system',
    'Initial platform personal-data policy state',
    'MIGRATION-000011'
from seed
on conflict (singleton_id) do nothing;

insert into platform_personal_data_policy_history (
    revision,
    previous_revision,
    previous_state,
    state,
    issued_at,
    valid_until,
    changed_at,
    actor,
    reason,
    change_ticket
)
select
    revision,
    null,
    null,
    state,
    issued_at,
    valid_until,
    changed_at,
    actor,
    reason,
    change_ticket
from platform_personal_data_policy_state
where singleton_id = 1
  and revision = 1
on conflict (revision) do nothing;

create or replace function enforce_platform_personal_data_policy_state_update()
returns trigger
language plpgsql
as $$
begin
    if new.singleton_id <> old.singleton_id then
        raise exception 'platform personal-data policy singleton id is immutable' using errcode = '23514';
    end if;
    if old.revision = 9223372036854775807 or new.revision <> old.revision + 1 then
        raise exception 'platform personal-data policy revision must advance by exactly one' using errcode = '23514';
    end if;
    if new.changed_at < old.changed_at then
        raise exception 'platform personal-data policy changed_at cannot move backwards' using errcode = '23514';
    end if;
    if new.state = old.state and (
        new.changed_at is distinct from old.changed_at
        or new.actor is distinct from old.actor
        or new.reason is distinct from old.reason
        or new.change_ticket is distinct from old.change_ticket
    ) then
        raise exception 'lease renewal cannot alter policy audit metadata' using errcode = '23514';
    end if;
    return new;
end;
$$;

create or replace function reject_platform_personal_data_policy_state_removal()
returns trigger
language plpgsql
as $$
begin
    raise exception 'platform personal-data policy singleton cannot be removed' using errcode = '55000';
end;
$$;

create or replace function reject_platform_personal_data_policy_history_mutation()
returns trigger
language plpgsql
as $$
begin
    raise exception 'platform personal-data policy history is append-only' using errcode = '55000';
end;
$$;

drop trigger if exists trg_platform_personal_data_policy_state_update
    on platform_personal_data_policy_state;
create trigger trg_platform_personal_data_policy_state_update
before update on platform_personal_data_policy_state
for each row execute function enforce_platform_personal_data_policy_state_update();

drop trigger if exists trg_platform_personal_data_policy_state_delete
    on platform_personal_data_policy_state;
create trigger trg_platform_personal_data_policy_state_delete
before delete on platform_personal_data_policy_state
for each row execute function reject_platform_personal_data_policy_state_removal();

drop trigger if exists trg_platform_personal_data_policy_state_truncate
    on platform_personal_data_policy_state;
create trigger trg_platform_personal_data_policy_state_truncate
before truncate on platform_personal_data_policy_state
for each statement execute function reject_platform_personal_data_policy_state_removal();

drop trigger if exists trg_platform_personal_data_policy_history_update
    on platform_personal_data_policy_history;
create trigger trg_platform_personal_data_policy_history_update
before update or delete on platform_personal_data_policy_history
for each row execute function reject_platform_personal_data_policy_history_mutation();

drop trigger if exists trg_platform_personal_data_policy_history_truncate
    on platform_personal_data_policy_history;
create trigger trg_platform_personal_data_policy_history_truncate
before truncate on platform_personal_data_policy_history
for each statement execute function reject_platform_personal_data_policy_history_mutation();
