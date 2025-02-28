;; Fishing License Contract - Enhanced Version
;; Manages issuance and tracking of fishing licenses with advanced features

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
(define-constant err-contract-paused (err u108))
(define-constant err-invalid-fee (err u109))

(define-constant min-duration u8760) ;; Minimum 2 months duration (in blocks)
(define-constant max-duration u52560) ;; Maximum 12 months duration (in blocks)

;; Data vars
(define-data-var license-counter uint u0)
(define-data-var license-fee uint u100) ;; in STX
(define-data-var renewal-fee uint u50) ;; in STX
(define-data-var transfer-fee uint u25) ;; in STX
(define-data-var contract-paused bool false)

;; Maps
(define-map license-details 
    {license-id: uint} 
    {holder: principal, license-type: (string-ascii 20), location: (string-ascii 50), renewal-count: uint})

(define-map transfer-allowance
    {license-id: uint}
    {approved-recipient: (optional principal)})

;; Events
(define-data-var last-event-id uint u0)

(define-private (emit-event (event-type (string-ascii 20)) (data (string-ascii 50)))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print {event-id: (var-get last-event-id), type: event-type, data: data})
    )
)

;; Private functions
(define-private (is-valid-license (license-id uint))
    (let ((license-data (nft-get-owner? fishing-license {license-id: license-id, expiry: block-height})))
        (and 
            (is-some license-data)
            (> (get expiry (unwrap-panic (nft-get? fishing-license license-id))) block-height)
        )
    )
)

(define-private (is-valid-duration (duration uint))
    (and 
        (>= duration min-duration)
        (<= duration max-duration)
    )
)

;; Admin functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused paused)
        (emit-event "contract-pause" (if paused "paused" "unpaused"))
        (ok true)
    )
)

(define-public (update-license-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> new-fee u0) err-invalid-fee)
        (var-set license-fee new-fee)
        (emit-event "fee-update" "license-fee-updated")
        (ok true)
    )
)

;; Public functions
(define-public (issue-license (holder principal) (license-type (string-ascii 20)) (location (string-ascii 50)) (duration uint))
    (let (
        (new-license-id (+ (var-get license-counter) u1))
        (expiry-height (+ block-height duration))
    )
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-duration duration) err-invalid-duration)
        
        (try! (stx-transfer? (var-get license-fee) holder contract-owner))
        (try! (nft-mint? fishing-license {license-id: new-license-id, expiry: expiry-height} holder))
        (map-set license-details {license-id: new-license-id} 
            {holder: holder, license-type: license-type, location: location, renewal-count: u0})
        (var-set license-counter new-license-id)
        (emit-event "license-issued" (concat (to-ascii new-license-id) "-issued"))
        (ok new-license-id)
    )
)

[Previous public functions remain unchanged]
