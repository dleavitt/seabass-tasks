# Seabass Tasks

## Tasks

- Recipients (list)
- Subject
- Body
- Status
  - Open
  - Claimed
  - Closed

### Redis
- tasks: (hash: subject body status claimed_by created_at)
- users: (list: task_id)