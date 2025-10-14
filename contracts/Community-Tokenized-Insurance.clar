
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-insufficient-funds (err u102))
(define-constant err-claim-not-found (err u103))
(define-constant err-claim-already-processed (err u104))
(define-constant err-voting-period-ended (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-invalid-amount (err u107))
(define-constant err-member-exists (err u108))
(define-constant err-minimum-stake-required (err u109))
(define-constant err-oracle-not-authorized (err u110))

(define-constant minimum-stake u1000000)
(define-constant claim-voting-period u1440)
(define-constant min-approval-threshold u60)
(define-constant auto-approval-threshold u100000)

(define-data-var total-pool-balance uint u0)
(define-data-var next-claim-id uint u1)
(define-data-var total-members uint u0)

(define-map members principal {
    stake-amount: uint,
    join-block: uint,
    active: bool
})

(define-map claims uint {
    claimant: principal,
    amount: uint,
    description: (string-ascii 256),
    submit-block: uint,
    votes-for: uint,
    votes-against: uint,
    total-voters: uint,
    processed: bool,
    approved: bool
})

(define-map claim-votes {claim-id: uint, voter: principal} bool)

(define-map authorized-oracles principal bool)

(define-public (join-pool (stake-amount uint))
    (let ((caller tx-sender))
        (asserts! (>= stake-amount minimum-stake) err-minimum-stake-required)
        (asserts! (is-none (map-get? members caller)) err-member-exists)
        (try! (stx-transfer? stake-amount caller (as-contract tx-sender)))
        (map-set members caller {
            stake-amount: stake-amount,
            join-block: stacks-block-height,
            active: true
        })
        (var-set total-pool-balance (+ (var-get total-pool-balance) stake-amount))
        (var-set total-members (+ (var-get total-members) u1))
        (ok true)
    )
)

(define-public (add-stake (additional-amount uint))
    (let (
        (caller tx-sender)
        (current-member (unwrap! (map-get? members caller) err-not-member))
    )
        (asserts! (get active current-member) err-not-member)
        (asserts! (> additional-amount u0) err-invalid-amount)
        (try! (stx-transfer? additional-amount caller (as-contract tx-sender)))
        (map-set members caller (merge current-member {
            stake-amount: (+ (get stake-amount current-member) additional-amount)
        }))
        (var-set total-pool-balance (+ (var-get total-pool-balance) additional-amount))
        (ok true)
    )
)

(define-public (leave-pool)
    (let (
        (caller tx-sender)
        (member-info (unwrap! (map-get? members caller) err-not-member))
        (stake-amount (get stake-amount member-info))
    )
        (asserts! (get active member-info) err-not-member)
        (asserts! (<= stake-amount (var-get total-pool-balance)) err-insufficient-funds)
        (try! (as-contract (stx-transfer? stake-amount tx-sender caller)))
        (map-set members caller (merge member-info {active: false}))
        (var-set total-pool-balance (- (var-get total-pool-balance) stake-amount))
        (var-set total-members (- (var-get total-members) u1))
        (ok true)
    )
)
(define-public (withdraw-partial-stake (withdraw-amount uint))
    (let (
        (caller tx-sender)
        (member-info (unwrap! (map-get? members caller) err-not-member))
        (current-stake (get stake-amount member-info))
    )
        (asserts! (get active member-info) err-not-member)
        (asserts! (> withdraw-amount u0) err-invalid-amount)
        (asserts! (<= withdraw-amount current-stake) err-insufficient-funds)
        (try! (as-contract (stx-transfer? withdraw-amount tx-sender caller)))
        (map-set members caller (merge member-info {
            stake-amount: (- current-stake withdraw-amount)
        }))
        (var-set total-pool-balance (- (var-get total-pool-balance) withdraw-amount))
        (ok true)
    )
)

(define-public (submit-claim (amount uint) (description (string-ascii 256)))
    (let (
        (caller tx-sender)
        (claim-id (var-get next-claim-id))
        (member-info (unwrap! (map-get? members caller) err-not-member))
        (auto-approve (<= amount auto-approval-threshold))
    )
        (asserts! (get active member-info) err-not-member)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (<= amount (var-get total-pool-balance)) err-insufficient-funds)
        (map-set claims claim-id {
            claimant: caller,
            amount: amount,
            description: description,
            submit-block: stacks-block-height,
            votes-for: u0,
            votes-against: u0,
            total-voters: u0,
            processed: auto-approve,
            approved: auto-approve
        })
        (var-set next-claim-id (+ claim-id u1))
        (if auto-approve
            (begin
                (try! (as-contract (stx-transfer? amount tx-sender caller)))
                (var-set total-pool-balance (- (var-get total-pool-balance) amount))
                (ok claim-id)
            )
            (ok claim-id)
        )
    )
)

(define-public (vote-on-claim (claim-id uint) (approve bool))
    (let (
        (caller tx-sender)
        (claim-info (unwrap! (map-get? claims claim-id) err-claim-not-found))
        (member-info (unwrap! (map-get? members caller) err-not-member))
        (vote-key {claim-id: claim-id, voter: caller})
    )
        (asserts! (get active member-info) err-not-member)
        (asserts! (not (get processed claim-info)) err-claim-already-processed)
        (asserts! (< (- stacks-block-height (get submit-block claim-info)) claim-voting-period) err-voting-period-ended)
        (asserts! (is-none (map-get? claim-votes vote-key)) err-already-voted)
        
        (map-set claim-votes vote-key true)
        
        (if approve
            (map-set claims claim-id (merge claim-info {
                votes-for: (+ (get votes-for claim-info) u1),
                total-voters: (+ (get total-voters claim-info) u1)
            }))
            (map-set claims claim-id (merge claim-info {
                votes-against: (+ (get votes-against claim-info) u1),
                total-voters: (+ (get total-voters claim-info) u1)
            }))
        )
        (ok true)
    )
)

(define-public (process-claim (claim-id uint))
    (let (
        (claim-info (unwrap! (map-get? claims claim-id) err-claim-not-found))
        (total-votes (get total-voters claim-info))
        (approval-percentage (if (> total-votes u0) 
            (/ (* (get votes-for claim-info) u100) total-votes) 
            u0))
    )
        (asserts! (not (get processed claim-info)) err-claim-already-processed)
        (asserts! (>= (- stacks-block-height (get submit-block claim-info)) claim-voting-period) err-voting-period-ended)
        
        (let ((approved (>= approval-percentage min-approval-threshold)))
            (map-set claims claim-id (merge claim-info {
                processed: true,
                approved: approved
            }))
            
            (if approved
                (begin
                    (try! (as-contract (stx-transfer? (get amount claim-info) tx-sender (get claimant claim-info))))
                    (var-set total-pool-balance (- (var-get total-pool-balance) (get amount claim-info)))
                    (ok {approved: true, paid: true})
                )
                (ok {approved: false, paid: false})
            )
        )
    )
)

(define-public (oracle-approve-claim (claim-id uint))
    (let (
        (caller tx-sender)
        (claim-info (unwrap! (map-get? claims claim-id) err-claim-not-found))
    )
        (asserts! (default-to false (map-get? authorized-oracles caller)) err-oracle-not-authorized)
        (asserts! (not (get processed claim-info)) err-claim-already-processed)
        
        (map-set claims claim-id (merge claim-info {
            processed: true,
            approved: true
        }))
        
        (try! (as-contract (stx-transfer? (get amount claim-info) tx-sender (get claimant claim-info))))
        (var-set total-pool-balance (- (var-get total-pool-balance) (get amount claim-info)))
        (ok true)
    )
)

(define-public (add-oracle (oracle-address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-oracles oracle-address true)
        (ok true)
    )
)

(define-public (remove-oracle (oracle-address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete authorized-oracles oracle-address)
        (ok true)
    )
)

(define-read-only (get-member-info (member principal))
    (map-get? members member)
)

(define-read-only (get-claim-info (claim-id uint))
    (map-get? claims claim-id)
)

(define-read-only (get-pool-balance)
    (var-get total-pool-balance)
)

(define-read-only (get-total-members)
    (var-get total-members)
)

(define-read-only (get-next-claim-id)
    (var-get next-claim-id)
)

(define-read-only (has-voted (claim-id uint) (voter principal))
    (is-some (map-get? claim-votes {claim-id: claim-id, voter: voter}))
)

(define-read-only (is-oracle-authorized (oracle principal))
    (default-to false (map-get? authorized-oracles oracle))
)

(define-read-only (calculate-claim-approval-rate (claim-id uint))
    (let (
        (claim-info (unwrap! (map-get? claims claim-id) err-claim-not-found))
        (total-votes (get total-voters claim-info))
    )
        (if (> total-votes u0)
            (ok (/ (* (get votes-for claim-info) u100) total-votes))
            (ok u0)
        )
    )
)

(define-read-only (is-claim-ready-for-processing (claim-id uint))
    (match (map-get? claims claim-id)
        claim-info (and 
            (not (get processed claim-info))
            (>= (- stacks-block-height (get submit-block claim-info)) claim-voting-period)
        )
        false
    )
)
