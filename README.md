# 🛡️ Community Tokenized Insurance

> 🤝 **Mutual insurance pool on Stacks blockchain - Trustless, transparent, community-driven coverage**

## 🎯 Overview

Community Tokenized Insurance is a decentralized mutual insurance platform that eliminates traditional insurance company intermediaries. Members pool their funds together and collectively decide on claim payouts through democratic voting or automated oracle verification.

## ✨ Key Features

- 🏦 **Mutual Pool System**: Members stake STX tokens to join the insurance pool
- 🗳️ **Democratic Claims**: Community votes on claim validity and payouts  
- 🤖 **Oracle Integration**: Automated claim verification for qualified events
- 💰 **Transparent Payouts**: All transactions visible on blockchain
- 🔒 **Trustless Operation**: No central authority controls funds

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX tokens

### Installation

```bash
git clone https://github.com/yourusername/Community-Tokenized-Insurance
cd Community-Tokenized-Insurance
clarinet project check
```

## 📋 Contract Functions

### 💼 Member Functions

#### Join Pool
```clarity
(contract-call? .Community-Tokenized-Insurance join-pool u5000000)
```
- **Purpose**: Join insurance pool by staking STX
- **Minimum**: 1,000,000 μSTX (1 STX)
- **Effect**: Becomes voting member

#### Add Stake
```clarity
(contract-call? .Community-Tokenized-Insurance add-stake u2000000)
```
- **Purpose**: Increase your stake in the pool
- **Benefit**: Higher voting weight (future feature)

#### Leave Pool
```clarity
(contract-call? .Community-Tokenized-Insurance leave-pool)
```
- **Purpose**: Exit pool and recover staked funds
- **Note**: Cannot leave with pending claims

### 📝 Claims Process

#### Submit Claim
```clarity
(contract-call? .Community-Tokenized-Insurance submit-claim u1000000 "Medical emergency - hospital bills")
```
- **Purpose**: Submit insurance claim
- **Requirements**: Must be active member
- **Voting Period**: 1,440 blocks (~10 days)

#### Vote on Claim
```clarity
(contract-call? .Community-Tokenized-Insurance vote-on-claim u1 true)
```
- **Purpose**: Vote approve/deny on community claims
- **Requirement**: Active pool member
- **Threshold**: 60% approval needed

#### Process Claim
```clarity
(contract-call? .Community-Tokenized-Insurance process-claim u1)
```
- **Purpose**: Execute payout after voting period
- **Automatic**: Anyone can trigger after voting ends
- **Payout**: Approved claims receive STX directly

### 🔮 Oracle Functions

#### Oracle Approval (Admin Only)
```clarity
(contract-call? .Community-Tokenized-Insurance oracle-approve-claim u1)
```
- **Purpose**: Instant claim approval via authorized oracle
- **Use Cases**: Weather events, crop failures, disasters
- **Bypass**: Skips community voting process

#### Manage Oracles (Owner Only)
```clarity
(contract-call? .Community-Tokenized-Insurance add-oracle 'SP1234...)
(contract-call? .Community-Tokenized-Insurance remove-oracle 'SP1234...)
```

### 📊 Read-Only Functions

#### Check Member Status
```clarity
(contract-call? .Community-Tokenized-Insurance get-member-info 'SP1234...)
```

#### View Claim Details
```clarity
(contract-call? .Community-Tokenized-Insurance get-claim-info u1)
```

#### Pool Statistics
```clarity
(contract-call? .Community-Tokenized-Insurance get-pool-balance)
(contract-call? .Community-Tokenized-Insurance get-total-members)
```

## 🎮 Usage Examples

### 🏥 Medical Insurance Scenario
1. **Community Formation**: 100 members each stake 5 STX
2. **Emergency Claim**: Member submits $2,000 medical claim
3. **Community Vote**: Members review and vote over 10 days
4. **Payout**: If 60%+ approve, STX automatically transferred

### 🌾 Agricultural Insurance
1. **Farmer Pool**: Agricultural community stakes funds
2. **Crop Loss**: Oracle detects drought/flood conditions
3. **Instant Payout**: Oracle approves claims automatically
4. **Community Support**: Farmers receive immediate relief

### 🏠 Disaster Recovery
1. **Neighborhood Pool**: Residents contribute to mutual fund
2. **Natural Disaster**: Hurricane damages multiple homes
3. **Mass Claims**: Multiple claims submitted simultaneously  
4. **Coordinated Response**: Community prioritizes urgent cases

## ⚙️ Configuration

### Contract Constants
- **Minimum Stake**: 1,000,000 μSTX (1 STX)
- **Voting Period**: 1,440 blocks (~10 days)
- **Approval Threshold**: 60%

### Error Codes
- `u100`: Owner only function
- `u101`: Not a member
- `u102`: Insufficient funds
- `u103`: Claim not found
- `u104`: Claim already processed
- `u105`: Voting period ended
- `u106`: Already voted
- `u107`: Invalid amount
- `u108`: Member already exists
- `u109`: Minimum stake required
- `u110`: Oracle not authorized

## 🔒 Security Features

- ✅ **Access Control**: Member-only claim submission
- ✅ **Double-Vote Prevention**: One vote per member per claim  
- ✅ **Time Locks**: Voting periods prevent rushed decisions
- ✅ **Oracle Authorization**: Only trusted oracles can bypass voting
- ✅ **Balance Checks**: Cannot payout more than pool balance

## 🛠️ Development

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request

## 📜 License

MIT License - Community driven, open source insurance for all

---

**🌟 Join the revolution in decentralized insurance - Where community trust replaces corporate gatekeepers**
