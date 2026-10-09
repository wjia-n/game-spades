# Spades — Rules (authoritative source of truth)

Cutthroat (individual, no partnerships) 4-seat trick-taking card game.
If the implementation ever conflicts with this document, the implementation
must be fixed.

## 1. Objective
Win tricks to make your bid. Score the most points over the match;
the first seat to reach the match target (250 or 500) ends the match,
and the highest score at that point wins.

## 2. Setup
- 4 seats, standard 52-card deck, no jokers.
- 13 cards dealt to each seat, one at a time, starting with the seat
  after the dealer. Dealer rotates every hand (seat 0 deals... in this
  implementation the deal starts to the dealer's left, and the dealer
  advances by one seat each hand; seat 0 leads the first hand's bidding).
- ♠ Spades are the permanent trump suit.

## 3. Turn order
- Bidding: in seat order starting left of the dealer, each seat bids once.
- Play: the bidder left of the dealer leads the first trick.
  The winner of each trick leads the next trick.

## 4. Legal moves
- **Leading:** any card in hand may be led, EXCEPT a spade may not be led
  until spades have been broken — unless the leader holds only spades.
- **Following:** a player must follow the led suit if they hold any card
  of that suit. Otherwise they may play any card (including a spade to
  trump, or discard).

## 5. Illegal moves
- Leading spades before they are broken while holding any non-spade card.
- Failing to follow suit when able to.
- The UI dims illegal cards and plays an "invalid" sound on illegal taps;
  the engine rejects them and keeps the turn open.

## 6. Captures
Each trick is won by:
1. The highest spade played, if any spade was played, else
2. The highest card of the led suit.
Ranks: 2 < 3 < … < 10 < J < Q < K < A (ace high).

## 7. Special rules
- **Spades broken:** spades are "broken" the moment a spade is played on a
  trick (because the player could not follow suit, or discarded). From then
  on, spades may be led.
- **Nil bid:** a seat may bid NIL instead of a number (if nil is enabled).
  A successful nil (taking zero tricks) scores +100; taking any trick
  scores −100.
- **Reneging** is impossible: the engine only ever offers legal cards.

## 8. Scoring (per hand)
- Nil bid: +100 if 0 tricks taken, −100 otherwise.
- Made bid: `bid × 10 + (tricks − bid)` (overtricks = "bags", +1 each).
- Missed bid: `−bid × 10`.
- No bag penalties or 10-bag resets in this edition (documented deviation
  from tournament rules for a friendlier casual game).

## 9. Winning conditions
- After any hand where a seat reaches the match target, the match ends and
  the seat with the highest score wins.
- Ties for highest score are broken by seat order (seat 0 first).

## 10. Draw conditions
There are no draws: every match produces a winner by highest score.

## 11. AI strategy
- **Bidding:** count aces as near-certain tricks, kings/queens with
  2–3+ cards in suit as partial tricks, trump length beyond 3 and short
  side suits as extra value. Easy adds noise ±2 (clamped 1–8); medium adds
  ±1; hard bids the estimate straight.
- **Nil:** only with ≤1 estimated trick and no card above Q (hard: nothing
  above 10), with a small probability gate per difficulty.
- **Play:** lead low from the longest non-spade suit; when following, win
  cheaply with the lowest winning card when tricks are still needed and
  duck when not; trump short suits when needed and no spade is already
  winning; on nil, always duck with the lowest safe card.
- **Difficulties:** Chill (easy), Sharp (medium), Shark (hard, PRO).

## 12. Edge cases
- A hand where everyone bids low but tricks still total 13: overtricks are
  scored normally; nothing special happens.
- Nil bidder forced to win a trick (opponents may deliberately feed them):
  scored −100.
- Leading the 13th (last) trick with only spades: allowed even if spades
  were never broken (leader holds only spades).
- Game pause (app backgrounded, pause menu): the engine freezes its single
  phase timer; on resume the watchdog re-arms the current phase. A match
  can never be left in a stuck state.

## 13. Test cases
1. Deal gives exactly 13 cards to each seat; 52 total.
2. Leading a spade first trick with non-spades in hand → rejected.
3. Cannot follow suit → any card (incl. spade) is legal.
4. Highest spade beats ace of led suit; highest led-suit card wins when no
   spade played.
5. Bid 3, take 5 → 32 points. Bid 3, take 2 → −30.
6. Nil + 0 tricks → +100; nil + 1 trick → −100.
7. Score ≥ target after a hand → match ends; highest score wins.
8. Every bot turn shows a "thinking" banner and the played card animates
   onto the table — nothing is silently auto-played.
9. Pause mid-bot-turn → resume continues the same phase.
