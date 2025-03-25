;; Decentralized Prediction Market
;; Infrastructure for Market Creation and Participation

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-MARKET (err u3))
(define-constant ERR-ALREADY-RESOLVED (err u4))
(define-constant ERR-MARKET-NOT-EXPIRED (err u5))

(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var market-counter uint u0)

(define-map prediction-markets
    uint
    {
        creator: principal,
        description: (string-utf8 256),
        end-block: uint,
        resolved: bool,
        outcome: (optional bool)
    }
)

(define-map market-predictions
    {market-id: uint, predictor: principal}
    {prediction: bool}
)

(define-public (initialize-platform)
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin)) (err u1))
        (var-set platform-active true)
        (ok true)
    )
)

(define-public (create-market 
    (description (string-utf8 256))
    (duration uint))
    (let 
        (
            (market-id (var-get market-counter))
            (end-block (+ block-height duration))
        )
        (asserts! (var-get platform-active) (err u2))
        (map-set prediction-markets market-id {
            creator: tx-sender,
            description: description,
            end-block: end-block,
            resolved: false,
            outcome: none
        })
        (var-set market-counter (+ market-id u1))
        (ok market-id)
    )
)

(define-public (place-prediction 
    (market-id uint)
    (prediction bool))
    (let 
        (
            (market (unwrap! (map-get? prediction-markets market-id) (err u3)))
        )
        (asserts! (< block-height (get end-block market)) (err u4))
        (map-set market-predictions 
            {market-id: market-id, predictor: tx-sender}
            {prediction: prediction}
        )
        (ok true)
    )
)

(define-public (resolve-market 
    (market-id uint)
    (actual-outcome bool))
    (let 
        (
            (market (unwrap! (map-get? prediction-markets market-id) (err u3)))
        )
        (asserts! (>= block-height (get end-block market)) (err u5))
        (map-set prediction-markets market-id 
            (merge market {
                resolved: true, 
                outcome: (some actual-outcome)
            })
        )
        (ok true)
    )
)

(define-read-only (get-market-details (market-id uint))
    (map-get? prediction-markets market-id)
)