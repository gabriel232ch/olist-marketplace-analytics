# Stage 5E prioritization and opportunity sizing

## Why there is no composite score

The portfolios use ordered, visible rules. Commercial scale, execution, supply risk and confidence remain separate columns so a manager can see why a segment received its posture. A weighted score would hide trade-offs and imply unsupported precision.

## Category-state action rules

Only segments with at least 100 current delivered orders and at least 95% review coverage are ranked.

1. **Fix before growth:** current GMV at or above peer P75 and on-time below peer P25 or low-review above peer P75.
2. **Defend:** current GMV at or above peer P75, on-time at or above the peer median and low-review at or below its median.
3. **Grow:** below P75 current GMV, absolute growth at or above the median positive change among adequately observed growing peers, and strong execution.
4. **Investigate supply:** at least median GMV with no local seller, interstate share above P75 or top-seller share above P75.
5. **Deprioritize:** only when adequately observed, low-scale, declining and operationally weak.
6. **Monitor / Not ranked:** evidence does not satisfy an action rule or fails the volume/coverage gate.

The rule order matters: a high-value weak segment is Fix before growth even if it also has a supply-risk signal.

## Portfolio summary

| Action posture | Segments | Orders | Current GMV exposure | Observed late orders | Gap to peer-median on-time scenario |
|---|---:|---:|---:|---:|---:|
| Defend | 13 | 12,561 | R$1,575,723.47 | 655 | 0 |
| Fix before growth | 6 | 2,920 | R$409,170.12 | 405 | 210 |
| Grow | 2 | 1,019 | R$102,574.07 | 50 | 0 |
| Investigate supply | 14 | 3,385 | R$510,503.06 | 310 | 104 |
| Monitor | 69 | 18,599 | R$2,246,453.40 | 1,270 | 260 |
| Not ranked | 1,221 | 14,755 | R$2,373,701.00 | 1,395 | 694 |

The GMV column is value exposed to each posture, not a benefit estimate. The scenario column is the arithmetic difference between observed late orders and what the same denominator would imply at the peer median; it assumes comparability and does not predict an intervention effect.

## Seller portfolio summary

| Action posture | Sellers | Orders | Current GMV exposure | Observed late orders | Gap to peer-median on-time scenario |
|---|---:|---:|---:|---:|---:|
| Defend | 7 | 3,510 | R$446,260.22 | 208 | 0 |
| Fix before growth | 10 | 4,508 | R$789,760.59 | 503 | 189 |
| Grow | 3 | 914 | R$68,152.57 | 49 | 0 |
| Investigate | 14 | 2,600 | R$393,782.80 | 230 | 73 |
| Deprioritize | 1 | 164 | R$3,076.95 | 13 | 1 |
| Monitor | 58 | 12,187 | R$894,599.26 | 889 | 164 |
| Not ranked | 2,717 | 29,739 | R$4,622,492.73 | 2,192 | 909 |

The single Deprioritize seller is a rule-based portfolio signal, not a recommendation to terminate a seller. Contract economics, inventory, strategic assortment and seller capacity are unavailable.

## Route portfolio

Routes need at least 100 delivered orders. A route is **Fix route** when its late rate exceeds the eligible-route P75 of 11.92%. Thirteen routes qualify. Likely owner labels compare median seller-handling and carrier time with route P75 thresholds; they are diagnostic directions, not proof of responsibility.

## Validation

- Category-state, seller and route keys are unique: 1,325, 2,810 and 359 rows respectively.
- Each priority view preserves its diagnostic row count and reconciles exactly to R$7,218,125.12 current GMV.
- Ranked category-state, seller and route rows are 104, 93 and 50; zero ineligible rows received a ranked posture.
- Scenario gaps are nonnegative and never exceed their eligible denominators.

## Stage 5E gate

**Passed in the isolated PostgreSQL 18 validation database.** Priorities use explicit rules, show confidence separately, size observable exposure without profit claims, and reconcile to their source diagnostics.
