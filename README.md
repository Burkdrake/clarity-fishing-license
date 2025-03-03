# Fishing License Smart Contract

## Overview
A Clarity smart contract for managing fishing licenses on the Stacks blockchain.

## License Duration Rules
- Minimum license duration: 2 months (8760 blocks)
- Maximum license duration: 12 months (52560 blocks)
- Duration validation prevents issuing very short-term or excessively long licenses
- Helps maintain system integrity and reduces administrative overhead

## New Features
- Contract pause mechanism for emergency situations
- Enhanced fee management with tiered pricing
- License type validation system
- Rate limiting for license issuance
- Structured event tracking
- Security improvements

## Tiered Pricing
- 15% discount for licenses >= 10 months
- 10% discount for licenses >= 6 months
- Standard price for shorter durations

[Previous README content remains unchanged]
