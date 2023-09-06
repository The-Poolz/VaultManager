import { VaultManager } from "../typechain-types"
import { ethers } from "hardhat"

// To use truffle dashboard
// npx hardhat run scripts/deploy.ts --network truffleDashboard
async function main() {
    const VaultManager = await ethers.getContractFactory("VaultManager")
    const vaultManager: VaultManager = await VaultManager.deploy()
    await vaultManager.deployed()
    console.log("VaultManager deployed to:", vaultManager.address)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
