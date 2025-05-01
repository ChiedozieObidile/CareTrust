# CareTrust Funding

CareTrust is a blockchain-based charitable funding platform that enables transparent donation management and equitable aid distribution to verified beneficiaries.

## Overview

CareTrust Funding is a smart contract solution built on the Stacks blockchain that creates a transparent, auditable, and efficient system for charitable giving. The platform allows donors to contribute STX tokens to a shared fund, which administrators then distribute to verified beneficiaries based on need and eligibility.

## Key Features

- **Secure Donation Processing**: Accept and track STX donations with minimum donation thresholds
- **Transparent Fund Management**: All transactions are recorded on-chain for full auditability
- **Beneficiary Verification**: Admin-controlled registration process for aid recipients
- **Flexible Aid Distribution**: Distribute funds to beneficiaries based on needs assessment
- **Comprehensive Record-Keeping**: Track donation history and aid disbursement
- **Emergency Protocols**: Emergency mode for crisis management
- **Governance Controls**: Transfer administrative rights as needed

## Smart Contract Functions

### For Donors

- `make-donation`: Contribute STX to the fund
- `get-donor-information`: View donation history for a specific donor

### For Administrators

- `register-new-beneficiary`: Add a verified beneficiary to the registry
- `disburse-aid`: Send funds to registered beneficiaries
- `update-beneficiary-status`: Change a beneficiary's status
- `set-minimum-donation`: Adjust the minimum donation threshold
- `toggle-fund-status`: Enable/disable donation acceptance
- `enable-emergency-mode` / `disable-emergency-mode`: Activate/deactivate emergency protocols
- `transfer-admin-rights`: Change the fund administrator

### Read-Only Functions

- `get-fund-administrator`: View the current administrator address
- `get-fund-balance`: Check the total fund balance
- `get-beneficiary-information`: View details about a specific beneficiary
- `check-fund-operational-status`: Verify if the fund is currently active

## Error Handling

The contract includes comprehensive error handling to ensure secure operation:

- Authentication errors
- Fund balance validations
- Beneficiary registration checks
- Donation minimum thresholds
- Operational status verification

## Status Codes

Beneficiaries can have the following status codes:
- `active`: Currently eligible to receive aid
- `pending`: Under review for aid eligibility
- `suspended`: Temporarily not receiving aid
- `completed`: Aid program completed for this beneficiary

## Security Considerations

- Admin-only functions are protected by principal verification
- Fund transfers require sufficient balance validation
- Reasonable limits on donation amounts prevent errors
- Emergency mode allows for quick response to security incidents

## Implementation

The contract is implemented in Clarity, the smart contract language for the Stacks blockchain.

## Getting Started

To interact with the CareTrust contract:

1. Deploy the contract to the Stacks blockchain
2. Set up the initial fund administrator
3. Configure minimum donation amounts
4. Begin registering beneficiaries and accepting donations

## License

This project is licensed under the MIT License.