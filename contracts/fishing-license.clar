;; Define the contract
(define-non-fungible-token fishing-license {license-id: uint, expiry: uint})

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-license-exists (err u101))
(define-constant err-license-not-found (err u102))
(define-constant err-license-expired (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-renewal (err u105))
(define-constant err-transfer-not-allowed (err u106))
(define-constant err-invalid-duration (err u107))
(define-constant min-duration u8760) ;; Minimum 2 months duration (in blocks)

;; Data vars
(define-data-var license-counter uint u0)
(define-data-var license-fee uint u100) ;; in STX
(define-data-var renewal-fee uint u50) ;; in STX
(define-data-var transfer-fee uint u25) ;; in STX

;; Maps
(define-map license-details 
    {license-id: uint} 
    {holder: principal, license-type: (string-ascii 20), location: (string-ascii 50), renewal-count: uint})

(define-map transfer-allowance
    {license-id: uint}
    {approved-recipient: (optional principal)})

;; Private functions
(define-private (is-valid-license (license-id uint))
    (let ((license-data (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height})))
        (and 
            (is-some license-data)
            (> (get expiry (unwrap-panic (nft-get? fishing-license license-id))) block-height)
        )
    )
)

;; Private function to validate duration
(define-private (is-valid-duration (duration uint))
    (>= duration min-duration)
)

;; Public functions
(define-public (issue-license (holder principal) (license-type (string-ascii 20)) (location (string-ascii 50)) (duration uint))
    (let (
        (new-license-id (+ (var-get license-counter) u1))
        (expiry-height (+ block-height duration))
    )
        (if (is-eq tx-sender contract-owner)
            (if (is-valid-duration duration)
                (begin
                    (try! (stx-transfer? (var-get license-fee) holder contract-owner))
                    (try! (nft-mint? fishing-license {license-id: new-license-id, expiry: expiry-height} holder))
                    (map-set license-details {license-id: new-license-id} {holder: holder, license-type: license-type, location: location, renewal-count: u0})
                    (var-set license-counter new-license-id)
                    (ok new-license-id)
                )
                (err err-invalid-duration)
            )
            err-owner-only
        )
    )
)

[Rest of contract implementation remains unchanged]
