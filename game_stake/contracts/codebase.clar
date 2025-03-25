;; Decentralized Prediction Market - Stage 2
;; Enhanced Market Mechanics with Staking and Rewards

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-MARKET (err u3))
(define-constant ERR-ALREADY-RESOLVED (err u4))
(define-constant ERR-MARKET-NOT-EXPIRED (err u5))
(define-constant ERR-INSUFFICIENT-STAKE (err u6))

(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var market-counter uint u0)
(define-data-var base-stake uint u100000) ;; 0.1 STX base stake
(define-data-var reward-multiplier uint u2) ;; 2x reward for correct predictions

(define-map prediction-markets
    uint
    {
        creator: principal,
        description: (string-utf8 256),
        end-block: uint,
        total-pool: uint,
        resolved: bool,
        outcome: (optional bool)
    }
)

(define-map market-predictions
    {market-id: uint, predictor: principal}
    {
        prediction: bool,
        stake: uint
    }
)

(define-map prediction-results
    {market-id: uint, predictor: principal}
    {
        correct: bool,
        reward: uint
    }
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
            total-pool: u0,
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
            (stake (var-get base-stake))
        )
        (asserts! (< block-height (get end-block market)) (err u4))
        (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
        
        (map-set market-predictions 
            {market-id: market-id, predictor: tx-sender}
            {
                prediction: prediction,
                stake: stake
            }
        )
        
        (map-set prediction-markets market-id 
            (merge market {
                total-pool: (+ (get total-pool market) stake)
            })
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

(define-public (claim-market-reward 
    (market-id uint))
    (let 
        (
            (market (unwrap! (map-get? prediction-markets market-id) (err u3)))
            (prediction (unwrap! 
                (map-get? market-predictions 
                    {market-id: market-id, predictor: tx-sender}) 
                (err u6)
            ))
            (market-outcome (unwrap! (get outcome market) (err u4)))
        )
        (asserts! (get resolved market) (err u4))
        
        (if (is-eq (get prediction prediction) market-outcome)
            (let 
                (
                    (reward (* (get stake prediction) (var-get reward-multiplier)))
                )
                (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
                (map-set prediction-results 
                    {market-id: market-id, predictor: tx-sender}
                    {
                        correct: true,
                        reward: reward
                    }
                )
            )
            (map-set prediction-results 
                {market-id: market-id, predictor: tx-sender}
                {
                    correct: false,
                    reward: u0
                }
            )
        )
        
        (ok true)
    )
)

(define-read-only (get-market-details (market-id uint))
    (map-get? prediction-markets market-id)
)

(define-read-only (get-prediction-result 
    (market-id uint)
    (predictor principal))
    (map-get? prediction-results 
        {market-id: market-id, predictor: predictor})
)