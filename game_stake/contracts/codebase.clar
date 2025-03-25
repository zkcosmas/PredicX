;; Decentralized Prediction Market Platform
;; A blockchain-based prediction market with progressive market challenges and incentives

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-MARKET (err u3))
(define-constant ERR-ALREADY-RESOLVED (err u4))
(define-constant ERR-WRONG-PREDICTION (err u5))
(define-constant ERR-TIME-LOCKED (err u6))
(define-constant ERR-INSUFFICIENT-STAKE (err u7))
(define-constant ERR-INVALID-INPUT (err u8))

;; Data Variables
(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var current-market-id uint u0)
(define-data-var market-entry-stake uint u1000000) ;; 1 STX
(define-data-var total-market-pool uint u0)
(define-data-var max-market-reward uint u1000000000) ;; Reasonable max reward

;; Prediction Market Structure
(define-map prediction-markets
    uint
    {
        market-description: (string-utf8 256),
        resolution-condition: (string-utf8 256),
        market-deadline: uint,
        market-reward: uint,
        market-resolved: bool
    }
)

;; Predictor Progress Tracking
(define-map predictor-progress
    principal
    {
        current-market-level: uint,
        completed-markets: (list 20 uint),
        last-prediction-attempt: uint,
        total-markets-predicted: uint
    }
)

;; Predictor Prediction History
(define-map market-predictions
    {market: uint, predictor: principal}
    {
        prediction-count: uint,
        resolved-at: (optional uint)
    }
)

;; Top Predictors
(define-map market-top-predictors
    uint
    (list 10 {predictor: principal, prediction-block: uint})
)

;; Input Validation Functions
(define-private (is-platform-admin)
    (is-eq tx-sender (var-get platform-admin)))

(define-private (is-valid-market-id (market-id uint))
    (and (> market-id u0) (<= market-id u100)))

(define-private (is-valid-market-description (description (string-utf8 256)))
    (and 
        (> (len description) u0) 
        (<= (len description) u256)))

(define-private (is-valid-resolution-condition (condition (string-utf8 256)))
    (and 
        (> (len condition) u0) 
        (<= (len condition) u256)))

(define-private (is-valid-market-deadline (deadline uint))
    (> deadline block-height))

(define-private (is-valid-market-reward (reward uint))
    (and 
        (> reward u0) 
        (<= reward (var-get max-market-reward))))

;; Platform Management Functions
(define-public (initialize-prediction-platform)
    (begin
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (var-set platform-active true)
        (var-set current-market-id u0)
        (var-set total-market-pool u0)
        (ok true)))

(define-public (create-prediction-market
    (market-id uint)
    (market-description (string-utf8 256))
    (resolution-condition (string-utf8 256))
    (market-deadline uint)
    (market-reward uint))
    (begin
        ;; Input validation checks
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-market-id market-id) ERR-INVALID-INPUT)
        (asserts! (is-valid-market-description market-description) ERR-INVALID-INPUT)
        (asserts! (is-valid-resolution-condition resolution-condition) ERR-INVALID-INPUT)
        (asserts! (is-valid-market-deadline market-deadline) ERR-INVALID-INPUT)
        (asserts! (is-valid-market-reward market-reward) ERR-INVALID-INPUT)
        
        ;; Existing logic with validated inputs
        (map-set prediction-markets market-id
            {
                market-description: market-description,
                resolution-condition: resolution-condition,
                market-deadline: market-deadline,
                market-reward: market-reward,
                market-resolved: false
            })
        
        ;; Safe addition with overflow check
        (let ((new-total (+ (var-get total-market-pool) market-reward)))
            (asserts! (>= new-total (var-get total-market-pool)) ERR-INVALID-INPUT)
            (var-set total-market-pool new-total))
        
        (ok true)))

;; Predictor Registration
(define-public (register-predictor)
    (begin
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        ;; Require entry stake
        (try! (stx-transfer? (var-get market-entry-stake) tx-sender (var-get platform-admin)))
        
        (map-set predictor-progress tx-sender
            {
                current-market-level: u0,
                completed-markets: (list),
                last-prediction-attempt: u0,
                total-markets-predicted: u0
            })
        (ok true)))

;; Prediction Market Submission
(define-public (submit-prediction
    (market-id uint)
    (prediction-outcome (buff 32)))
    (let (
        (market (unwrap! (map-get? prediction-markets market-id) ERR-INVALID-MARKET))
        (predictor (unwrap! (map-get? predictor-progress tx-sender) ERR-INVALID-MARKET))
        )
        ;; Check platform availability
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        (asserts! (>= block-height (get market-deadline market)) ERR-TIME-LOCKED)
        (asserts! (not (get market-resolved market)) ERR-ALREADY-RESOLVED)
        
        ;; Verify prediction - directly compare the outcomes
        (if (is-eq prediction-outcome 0x01)  ;; Simplified binary outcome
            (begin
                ;; Update market status
                (map-set prediction-markets market-id
                    (merge market {market-resolved: true}))
                
                ;; Update predictor progress
                (map-set predictor-progress tx-sender
                    (merge predictor {
                        current-market-level: (+ market-id u1),
                        completed-markets: (unwrap! (as-max-len? 
                            (append (get completed-markets predictor) market-id) u20)
                            ERR-INVALID-MARKET),
                        total-markets-predicted: (+ (get total-markets-predicted predictor) u1)
                    }))
                
                ;; Record prediction
                (map-set market-predictions
                    {market: market-id, predictor: tx-sender}
                    {
                        prediction-count: u1,
                        resolved-at: (some block-height)
                    })
                
                ;; Award market reward
                (try! (stx-transfer? (get market-reward market) (var-get platform-admin) tx-sender))
                
                ;; Record top predictors
                (match (map-get? market-top-predictors market-id)
                    top-predictors (map-set market-top-predictors market-id
                        (unwrap! (as-max-len?
                            (append top-predictors {predictor: tx-sender, prediction-block: block-height})
                            u10)
                            ERR-INVALID-MARKET))
                    (map-set market-top-predictors market-id
                        (list {predictor: tx-sender, prediction-block: block-height})))
                
                (ok true))
            ERR-WRONG-PREDICTION)))

;; Read-only functions
(define-read-only (get-current-market-details (market-id uint))
    (match (map-get? prediction-markets market-id)
        market (if (>= block-height (get market-deadline market))
            (ok (get market-description market))
            ERR-TIME-LOCKED)
        ERR-INVALID-MARKET))

(define-read-only (get-predictor-status (predictor principal))
    (map-get? predictor-progress predictor))

(define-read-only (get-market-top-predictors (market-id uint))
    (map-get? market-top-predictors market-id))

(define-read-only (get-platform-stats)
    {
        active: (var-get platform-active),
        current-market-id: (var-get current-market-id),
        total-market-pool: (var-get total-market-pool),
        market-entry-stake: (var-get market-entry-stake)
    })