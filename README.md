# CorporateChain

A decentralized corporate board decision management system for transparent corporate governance on Stacks blockchain.

## Features

- Corporate proposal submission and management
- Board director voting with share-weighted decisions
- Proxy assignment for board representation
- Quarterly governance cycles and timeline management
- Comprehensive corporate governance statistics

## Smart Contract Functions

### Public Functions
- `submit-proposal` - Submit corporate proposal for board voting (chairman only)
- `cast-board-vote` - Cast vote on corporate proposal with share weight
- `assign-proxy` - Assign proxy for board representation
- `close-proposal` - Close proposal voting (chairman only)
- `advance-quarter` - Advance quarterly governance cycle (chairman only)

### Read-Only Functions
- `get-proposal-shares-total` - Get total shares voted on proposal
- `get-director-shares-level` - Get director's share allocation
- `get-proposal-status` - Check if proposal voting is active
- `get-current-quarter` - Get current governance quarter
- `get-board-stats` - Get comprehensive board statistics

## Governance Features
- Share-weighted voting system
- Proxy representation mechanism
- Quarterly decision cycles
- Chairman authorization controls

## Usage

Deploy the contract to create a corporate governance system where board directors can submit proposals, vote with share weights, and manage corporate decisions transparently.

## License

MIT