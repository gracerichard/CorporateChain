;; CorporateChain - Corporate Board Decision Management System
;; Version: 1.0.0

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_EXISTS (err u101))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CHOICE (err u105))
(define-constant ERR_SELF_REPRESENTATION (err u106))
(define-constant ERR_REPRESENTATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_SHARES (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var board-chairman principal tx-sender)
(define-data-var quarter-counter uint u0)

;; Maps
(define-map Proposals
  { proposal-id: uint }
  {
    title: (string-ascii 50),
    options: (list 10 (string-ascii 20)),
    deadline: uint,
    shares-total: uint
  })

(define-map BoardVotes
  { proposal-id: uint, director: principal }
  { option: (string-ascii 20), shares: uint })

(define-map DirectorShares
  { director: principal }
  { shares: uint })

(define-map Proxies
  { grantor: principal }
  { proxy: principal })

;; Private Functions
(define-private (is-board-chairman)
  (is-eq tx-sender (var-get board-chairman)))

(define-private (check-proposal-exists (proposal-id uint))
  (is-some (map-get? Proposals { proposal-id: proposal-id })))

(define-private (check-voting-open (proposal-id uint))
  (match (map-get? Proposals { proposal-id: proposal-id })
    proposal-data (< (var-get quarter-counter) (get deadline proposal-data))
    false))

(define-private (get-director-shares (director principal))
  (default-to u1 (get shares (map-get? DirectorShares { director: director }))))

(define-private (update-shares-total (proposal-id uint) (shares uint))
  (match (map-get? Proposals { proposal-id: proposal-id })
    proposal-data (map-set Proposals
                 { proposal-id: proposal-id }
                (merge proposal-data { shares-total: (+ (get shares-total proposal-data) shares) }))
    false))

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50)))

(define-private (validate-options (options (list 10 (string-ascii 20))))
  (and 
    (>= (len options) u2)
    (<= (len options) u10)
    (fold and (map validate-string options) true)
  ))

(define-private (validate-shares-threshold (director principal))
  (> (get-director-shares director) u0))

;; Public Functions
(define-public (submit-proposal (title (string-ascii 50)) (options (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-board-chairman) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-options options) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (proposal-id (+ u1 (default-to u0 (get shares-total (map-get? Proposals { proposal-id: u0 })))))
        (current-quarter (var-get quarter-counter))
      )
      (asserts! (not (check-proposal-exists proposal-id)) ERR_PROPOSAL_EXISTS)
      (ok (map-set Proposals
            { proposal-id: proposal-id }
            {
              title: title,
              options: options,
              deadline: (+ current-quarter duration),
              shares-total: u0
            }))
    )
  ))

(define-public (cast-board-vote (proposal-id uint) (option (string-ascii 20)))
  (let 
    (
      (director-shares (get-director-shares tx-sender))
      (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
    )
    (asserts! (check-voting-open proposal-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get options proposal) option)) ERR_INVALID_CHOICE)
    (asserts! (is-none (map-get? BoardVotes { proposal-id: proposal-id, director: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-shares-threshold tx-sender) ERR_NOT_ENOUGH_SHARES)
    (map-set BoardVotes
      { proposal-id: proposal-id, director: tx-sender }
      { option: option, shares: director-shares })
    (update-shares-total proposal-id director-shares)
    (ok true)
  ))

(define-public (assign-proxy (proxy principal))
  (begin
    (asserts! (not (is-eq tx-sender proxy)) ERR_SELF_REPRESENTATION)
    (asserts! (is-none (map-get? Proxies { grantor: proxy })) ERR_REPRESENTATION_CYCLE)
    (map-set Proxies { grantor: tx-sender } { proxy: proxy })
    (map-set DirectorShares
      { director: proxy }
      { shares: (+ (get-director-shares proxy) (get-director-shares tx-sender)) })
    (map-delete DirectorShares { director: tx-sender })
    (ok true)
  ))

(define-public (close-proposal (proposal-id uint))
  (begin
    (asserts! (is-board-chairman) ERR_UNAUTHORIZED)
    (asserts! (check-proposal-exists proposal-id) ERR_PROPOSAL_NOT_FOUND)
    (let ((proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
      (ok (map-set Proposals
            { proposal-id: proposal-id }
            (merge proposal { deadline: (var-get quarter-counter) })))
    )
  ))

(define-public (advance-quarter)
  (begin
    (asserts! (is-board-chairman) ERR_UNAUTHORIZED)
    (ok (var-set quarter-counter (+ (var-get quarter-counter) u1)))
  ))

;; Read-Only Functions
(define-read-only (get-proposal-shares-total (proposal-id uint))
  (ok (get shares-total (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))))

(define-read-only (get-director-shares-level (director principal))
  (ok (get-director-shares director)))

(define-read-only (get-proposal-status (proposal-id uint))
  (let ((proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (ok (< (var-get quarter-counter) (get deadline proposal)))
  ))

(define-read-only (get-current-quarter)
  (ok (var-get quarter-counter)))

(define-read-only (get-board-stats)
  {
    chairman: (var-get board-chairman),
    current-quarter: (var-get quarter-counter)
  })