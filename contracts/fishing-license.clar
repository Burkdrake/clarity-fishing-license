;; Define the contract
(define-non-fungible-token fishing-license {license-id: uint, expiry: uint})

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-license-exists (err u101))
(define-constant err-license-not-found (err u102))
(define-constant err-license-expired (err u103))
(define-constant err-unauthorized (err u104))

;; Data vars
(define-data-var license-counter uint u0)
(define-data-var license-fee uint u100) ;; in STX

;; Maps
(define-map license-details 
    {license-id: uint} 
    {holder: principal, license-type: (string-ascii 20), location: (string-ascii 50)})

;; Private functions
(define-private (is-valid-license (license-id uint))
    (let ((license-data (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height})))
        (and 
            (is-some license-data)
            (> (get expiry (unwrap-panic (nft-get? fishing-license license-id))) block-height)
        )
    )
)

;; Public functions
(define-public (issue-license (holder principal) (license-type (string-ascii 20)) (location (string-ascii 50)) (duration uint))
    (let (
        (new-license-id (+ (var-get license-counter) u1))
        (expiry-height (+ block-height duration))
    )
        (if (is-eq tx-sender contract-owner)
            (begin
                (try! (stx-transfer? (var-get license-fee) holder contract-owner))
                (try! (nft-mint? fishing-license {license-id: new-license-id, expiry: expiry-height} holder))
                (map-set license-details {license-id: new-license-id} {holder: holder, license-type: license-type, location: location})
                (var-set license-counter new-license-id)
                (ok new-license-id)
            )
            err-owner-only
        )
    )
)

(define-public (revoke-license (license-id uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (try! (nft-burn? fishing-license {license-id: license-id, expiry: block-height} contract-owner))
            (ok true)
        )
        err-owner-only
    )
)

;; Read only functions
(define-read-only (get-license-details (license-id uint))
    (ok (map-get? license-details {license-id: license-id}))
)

(define-read-only (check-license-validity (license-id uint))
    (ok (is-valid-license license-id))
)

(define-read-only (get-license-fee)
    (ok (var-get license-fee))
)
