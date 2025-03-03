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
(define-constant err-invalid-license-type (err u110))
(define-constant err-rate-limit (err u111))

(define-constant min-duration u8760) ;; Minimum 2 months duration
(define-constant max-duration u52560) ;; Maximum 12 months duration

;; Data vars
(define-data-var license-counter uint u0)
(define-data-var license-fee uint u100)
(define-data-var renewal-fee uint u50)
(define-data-var transfer-fee uint u25)
(define-data-var contract-paused bool false)
(define-data-var last-issuance-block uint u0)
(define-data-var issuance-cooldown uint u10) ;; Blocks between issuances

;; Maps
(define-map license-details 
    {license-id: uint} 
    {holder: principal, license-type: (string-ascii 20), location: (string-ascii 50), renewal-count: uint})

(define-map valid-license-types
    (string-ascii 20)
    bool)

(define-map transfer-allowance
    {license-id: uint}
    {approved-recipient: (optional principal)})

;; Enhanced Events
(define-data-var last-event-id uint u0)

(define-private (emit-event (event-type (string-ascii 20)) (data {action: (string-ascii 20), details: (string-ascii 50), timestamp: uint}))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print {
            event-id: (var-get last-event-id),
            type: event-type,
            data: data,
            block: block-height
        })
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

(define-private (calculate-tiered-fee (duration uint))
    (let ((base-fee (var-get license-fee)))
        (if (>= duration u43800) ;; 10 months
            (/ (* base-fee u85) u100) ;; 15% discount
            (if (>= duration u26280) ;; 6 months
                (/ (* base-fee u90) u100) ;; 10% discount
                base-fee
            )
        )
    )
)

;; Admin functions
(define-public (add-valid-license-type (license-type (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set valid-license-types license-type true)
        (emit-event "admin" {
            action: "add-license-type",
            details: license-type,
            timestamp: block-height
        })
        (ok true)
    )
)

;; [Previous admin functions remain unchanged]

;; Enhanced public functions
(define-public (issue-license (holder principal) (license-type (string-ascii 20)) (location (string-ascii 50)) (duration uint))
    (let (
        (new-license-id (+ (var-get license-counter) u1))
        (expiry-height (+ block-height duration))
        (actual-fee (calculate-tiered-fee duration))
    )
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-duration duration) err-invalid-duration)
        (asserts! (default-to false (map-get? valid-license-types license-type)) err-invalid-license-type)
        (asserts! (>= (- block-height (var-get last-issuance-block)) (var-get issuance-cooldown)) err-rate-limit)
        
        (try! (stx-transfer? actual-fee holder contract-owner))
        (try! (nft-mint? fishing-license {license-id: new-license-id, expiry: expiry-height} holder))
        (map-set license-details {license-id: new-license-id} 
            {holder: holder, license-type: license-type, location: location, renewal-count: u0})
        (var-set license-counter new-license-id)
        (var-set last-issuance-block block-height)
        (emit-event "license" {
            action: "issue",
            details: (concat license-type "-" location),
            timestamp: block-height
        })
        (ok new-license-id)
    )
)

;; [Previous public functions remain unchanged]
