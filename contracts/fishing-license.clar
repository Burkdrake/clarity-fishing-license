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
                (map-set license-details {license-id: new-license-id} {holder: holder, license-type: license-type, location: location, renewal-count: u0})
                (var-set license-counter new-license-id)
                (ok new-license-id)
            )
            err-owner-only
        )
    )
)

(define-public (renew-license (license-id uint) (duration uint))
    (let (
        (current-owner (unwrap! (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height}) err-license-not-found))
        (current-details (unwrap! (map-get? license-details {license-id: license-id}) err-license-not-found))
        (new-expiry (+ block-height duration))
    )
        (if (is-eq tx-sender current-owner)
            (begin
                (try! (stx-transfer? (var-get renewal-fee) current-owner contract-owner))
                (try! (nft-burn? fishing-license {license-id: license-id, expiry: block-height} current-owner))
                (try! (nft-mint? fishing-license {license-id: license-id, expiry: new-expiry} current-owner))
                (map-set license-details 
                    {license-id: license-id} 
                    (merge current-details {renewal-count: (+ (get renewal-count current-details) u1)}))
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-public (approve-transfer (license-id uint) (recipient (optional principal)))
    (let ((current-owner (unwrap! (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height}) err-license-not-found)))
        (if (is-eq tx-sender current-owner)
            (begin
                (map-set transfer-allowance {license-id: license-id} {approved-recipient: recipient})
                (ok true)
            )
            err-unauthorized
        )
    )
)

(define-public (transfer-license (license-id uint) (recipient principal))
    (let (
        (current-owner (unwrap! (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height}) err-license-not-found))
        (current-details (unwrap! (map-get? license-details {license-id: license-id}) err-license-not-found))
        (transfer-approval (unwrap! (map-get? transfer-allowance {license-id: license-id}) err-transfer-not-allowed))
    )
        (if (and 
                (is-eq tx-sender current-owner)
                (or 
                    (is-none (get approved-recipient transfer-approval))
                    (is-eq (some recipient) (get approved-recipient transfer-approval))
                )
            )
            (begin
                (try! (stx-transfer? (var-get transfer-fee) recipient contract-owner))
                (try! (nft-transfer? fishing-license {license-id: license-id, expiry: block-height} current-owner recipient))
                (map-set license-details 
                    {license-id: license-id}
                    (merge current-details {holder: recipient}))
                (map-delete transfer-allowance {license-id: license-id})
                (ok true)
            )
            err-unauthorized
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

(define-read-only (get-renewal-fee)
    (ok (var-get renewal-fee))
)

(define-read-only (get-transfer-fee)
    (ok (var-get transfer-fee))
)

(define-read-only (get-transfer-approval (license-id uint))
    (ok (map-get? transfer-allowance {license-id: license-id}))
)
