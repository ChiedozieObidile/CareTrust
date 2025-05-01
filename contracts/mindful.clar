;; CareTrust Funding Smart Contract
;; Handles donations, fund distribution, and beneficiary management

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ADMIN-ACCESS (err u100))
(define-constant ERR-BENEFICIARY-DUPLICATE (err u101))
(define-constant ERR-BENEFICIARY-NONEXISTENT (err u102))
(define-constant ERR-FUND-BALANCE-INSUFFICIENT (err u103))
(define-constant ERR-DONATION-MINIMUM-NOT-MET (err u104))
(define-constant ERR-CONTRACT-NOT-ACTIVE (err u105))
(define-constant ERR-DONATION-AMOUNT-INVALID (err u106))
(define-constant ERR-BENEFICIARY-STATUS-INVALID (err u107))
(define-constant ERR-ADMIN-ADDRESS-INVALID (err u108))

;; Data Variables
(define-data-var fund-administrator principal tx-sender)
(define-data-var fund-balance-total uint u0)
(define-data-var fund-active-status bool true)
(define-data-var donation-minimum-amount uint u1000000) ;; 1 STX
(define-data-var fund-emergency-mode bool false)

;; Data Maps
(define-map beneficiary-registry 
    principal 
    {
        is-beneficiary-active: bool,
        aid-funds-received: uint,
        last-aid-block: uint,
        current-aid-status: (string-ascii 20)
    }
)

(define-map donor-registry
    principal
    {
        total-donations-made: uint,
        last-donation-block: uint
    }
)

;; Read-only functions
(define-read-only (get-fund-administrator)
    (var-get fund-administrator)
)

(define-read-only (get-fund-balance)
    (var-get fund-balance-total)
)

(define-read-only (get-beneficiary-information (beneficiary-wallet principal))
    (map-get? beneficiary-registry beneficiary-wallet)
)

(define-read-only (get-donor-information (donor-wallet principal))
    (map-get? donor-registry donor-wallet)
)

(define-read-only (check-fund-operational-status)
    (and (var-get fund-active-status) (not (var-get fund-emergency-mode)))
)

;; Private functions
(define-private (verify-admin-privileges)
    (is-eq tx-sender (var-get fund-administrator))
)

(define-private (update-donor-history (donor-wallet principal) (donation-value uint))
    (let (
        (existing-donor-record (default-to 
            { total-donations-made: u0, last-donation-block: u0 } 
            (map-get? donor-registry donor-wallet)
        ))
    )
    (map-set donor-registry
        donor-wallet
        {
            total-donations-made: (+ (get total-donations-made existing-donor-record) donation-value),
            last-donation-block: block-height
        }
    ))
)

;; Private validation functions
(define-private (validate-donation-amount (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Set reasonable upper limit
    )
)

(define-private (validate-beneficiary-status (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "active")
        (is-eq status-code "pending")
        (is-eq status-code "suspended")
        (is-eq status-code "completed")
    )
)

(define-private (validate-admin-address (wallet-address principal))
    (and 
        (not (is-eq wallet-address (var-get fund-administrator)))
        (not (is-eq wallet-address (as-contract tx-sender)))
    )
)

;; Public functions
(define-public (make-donation)
    (let (
        (donation-value (stx-get-balance tx-sender))
    )
    (asserts! (>= donation-value (var-get donation-minimum-amount)) ERR-DONATION-MINIMUM-NOT-MET)
    (asserts! (check-fund-operational-status) ERR-CONTRACT-NOT-ACTIVE)
    
    (try! (stx-transfer? donation-value tx-sender (as-contract tx-sender)))
    (var-set fund-balance-total (+ (var-get fund-balance-total) donation-value))
    (update-donor-history tx-sender donation-value)
    (ok donation-value))
)

(define-public (register-new-beneficiary (beneficiary-wallet principal))
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (asserts! (is-none (map-get? beneficiary-registry beneficiary-wallet)) ERR-BENEFICIARY-DUPLICATE)
        
        (map-set beneficiary-registry 
            beneficiary-wallet
            {
                is-beneficiary-active: true,
                aid-funds-received: u0,
                last-aid-block: u0,
                current-aid-status: "active"
            }
        )
        (ok true)
    )
)

(define-public (disburse-aid (beneficiary-wallet principal) (aid-amount uint))
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (asserts! (check-fund-operational-status) ERR-CONTRACT-NOT-ACTIVE)
        (asserts! (>= (var-get fund-balance-total) aid-amount) ERR-FUND-BALANCE-INSUFFICIENT)
        (asserts! 
            (is-some (map-get? beneficiary-registry beneficiary-wallet)) 
            ERR-BENEFICIARY-NONEXISTENT
        )
        
        (try! (as-contract (stx-transfer? aid-amount tx-sender beneficiary-wallet)))
        (var-set fund-balance-total (- (var-get fund-balance-total) aid-amount))
        
        (let (
            (beneficiary-record (unwrap! (map-get? beneficiary-registry beneficiary-wallet) ERR-BENEFICIARY-NONEXISTENT))
        )
        (map-set beneficiary-registry
            beneficiary-wallet
            {
                is-beneficiary-active: (get is-beneficiary-active beneficiary-record),
                aid-funds-received: (+ (get aid-funds-received beneficiary-record) aid-amount),
                last-aid-block: block-height,
                current-aid-status: (get current-aid-status beneficiary-record)
            }
        )
        (ok aid-amount))
    )
)

;; Administrative functions
(define-public (set-minimum-donation (new-minimum-value uint))
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (asserts! (validate-donation-amount new-minimum-value) ERR-DONATION-AMOUNT-INVALID)
        (var-set donation-minimum-amount new-minimum-value)
        (ok true)
    )
)

(define-public (toggle-fund-status)
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (var-set fund-active-status (not (var-get fund-active-status)))
        (ok true)
    )
)

(define-public (enable-emergency-mode)
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (var-set fund-emergency-mode true)
        (ok true)
    )
)

(define-public (disable-emergency-mode)
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (var-set fund-emergency-mode false)
        (ok true)
    )
)

(define-public (update-beneficiary-status (beneficiary-wallet principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (asserts! (validate-beneficiary-status new-status) ERR-BENEFICIARY-STATUS-INVALID)
        (asserts! 
            (is-some (map-get? beneficiary-registry beneficiary-wallet)) 
            ERR-BENEFICIARY-NONEXISTENT
        )
        
        (let (
            (current-record (unwrap! (map-get? beneficiary-registry beneficiary-wallet) ERR-BENEFICIARY-NONEXISTENT))
        )
        (map-set beneficiary-registry
            beneficiary-wallet
            {
                is-beneficiary-active: (get is-beneficiary-active current-record),
                aid-funds-received: (get aid-funds-received current-record),
                last-aid-block: (get last-aid-block current-record),
                current-aid-status: new-status
            }
        )
        (ok true))
    )
)

;; Transfer ownership
(define-public (transfer-admin-rights (new-admin-address principal))
    (begin
        (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ADMIN-ACCESS)
        (asserts! (validate-admin-address new-admin-address) ERR-ADMIN-ADDRESS-INVALID)
        (var-set fund-administrator new-admin-address)
        (ok true)
    )
)