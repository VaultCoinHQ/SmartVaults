# Hybrid Custody™ using Layer 2 Smart Vaults™ - POC Implementation & Technology Demo

**Hybrid Custody™** using Layer 2 Smart Vaults™ makes Bitcoin and other similar Altcoins **Unstealable, Unlosable and Unconfiscatable** for all practical purposes.

While securing one’s private-keys might seem trivial at first but ensuring safety i.e. preventing data loss (lost private-key) along with absolute security i.e. preventing data theft (stolen private key) is very difficult if not impossible. It is a balancing act and one has to sacrifice a bit of security to increase safety and vice versa. Eg. Increasing the number of places where you store copies of your private-keys increases safety but decreases security as they can now be stolen from more places than before.

Several methods and devices were proposed and implemented to alleviate this problem at least partially but none are as flexible and secure as one would desire them to be.

Moreover, most devices, platforms and frameworks we use to generate our private-keys, store them securely and sign transactions with them have many known and unknown vulnerabilities. Relying solely on these contraptions and OPSEC to secure our Bitcoin can be risky to say the least.

Inheritance planning has also been a pain point for Crypto adoption. Self Custody of Bitcoin necessisates that we share the  credentials and more with our beneficiaries before hand complicating OPSEC and personal lives for everyone involved. Many a times, sharing credentials with beneficiaries is not even practically possible. Eg. Children.

This protocol and framework assumes that our private-keys will be lost or stolen, sooner than later, and provides recourse even in those situations while handling inheritance seamlessly.

# Smart Vaults

Smart Vaults™ (Layer 2) are like Multisig or MPC Vaults on steroids. Key difference is that you can assign priorities to private-keys participating in a Smart Vault™.

## Next-Gen Scalable Security

1. "Unlocking" and "Spending" from your Smart Vault™ are distinct events (transactions) with a programmable delay between them unlike MultiSig/MPC Vaults.
2. The mandatory "Unlock" which is visible on-chain as a transaction alerts all participants of a Smart Vault™ to take corrective actions if the unlock was not initiated by them in the first place.
3. When `m private-keys` are presumably used by an adversary to unlock-and-spend from your Smart Vault™ locked with `n private-keys`, you can use any `m+1 private-keys upto n` to override the malicious unlock-and-spend attempt and recover your Bitcoin before the preset delay expires i.e. `m-to-n of n`. (Assuming all private-keys have equal priority.)
4. Stealing becomes impossible unless adversaries have all the `n private-keys`.
5. Can be customized to allow some private-keys and combinations to override other private-keys and combinations.
6. Use simple yet powerful Zero-Disclosure Proofs to determine which private-keys and combinations take precedence over other private-keys and combinations.
7. Protects against hacks, social engineering, insider fraud, etc.
8. Optional on-chain “Out of Band” Authentication & Autherization with Hardware Tokens (proprietary technology).

## Supercharged Safety

1. Even `1 private-key` is enough to recover your Bitcoin from Smart Vaults™ locked with `n private-keys` i.e. `1-to-n of n`.
2. Can tolerate loss of `n-1 private-keys`
3. Useful for disaster management, accidental loss, unexpected death and factors beyond control.

# Hybrid Custody using Smart Vaults

To put it briefly, Hybrid Custody™ is a framework built on top of Smart Vaults™ and combines the best of "Self Custody" and "Managed Custody".

You have absolute control of your private-keys and coins just like "Self Custody" and you can recover your Bitcoin even when all your private-keys are lost or stolen as if you opted for fully "Managed Custody" and you never needed to manage your private-keys to begin with. It's almost magic!

With just a simple MultiSig transaction and a couple of Partially Signed Bitcoin Transactions distributed rather cleverly between the participants, Hybrid Custody using L2 Smart Vaults drastically increases the safety/security of your Bitcoin and even handles inheritance for you without any prior arrangements with your beneficiaries. (Watch videos linked below for detailed explanation of the Layer 2 protocol)

This repository demostrates the feasibility and steps involved during setup, termination and recovery from Smart Vaults™ in their most basic form with just one private-key from "User" and one private-key from "Sentinel" who doubles up as a Hybrid Custody Provider. 

When User's private key is lost, he can recover his Bitcoin using just Sentinel's private key as with any Managed Custody Provider.

And when User's private-key is stolen and used to initiate the unlock-and-spend process, User can cosign a recovery transaction with Sentinel, override the malicious attempt and safely recover his Bitcoin.

Lastly, if Sentinel tries to steal User's Bitcoin using it's private-key, User can always override that unlock-and-spend attempt and safely transfer his Bitcoin to wherever he wishes using just his private-key.

The POC Implementation in this GitHub repo clearly demonstrates all these scenarios.

Once you get this, you can easily extend your undertanding to include more factors/private-keys as well as complex contingency planning using multiple factors/private-keys from multiple participants.

>Proprietary Technology - See **Legal Notice** below!

Everything is explained in detail in the videos below.

## Hybrid Custody using Smart Vaults - Technology Overview (Video)

[![Hybrid Custody using Smart Vaults - Technology Overview (Video)](https://img.youtube.com/vi/IQqM77cRdIM/mqdefault.jpg)](https://www.youtube.com/watch?v=pEIcKoIA0nY)

https://www.youtube.com/watch?v=pEIcKoIA0nY (Click to play)

## Proof Of Concept Implementation - Setup (Local)

1. Download Bitcoin Core (v25) binary archive for your platform from here - https://bitcoincore.org/bin/bitcoin-core-25.0/
2. Extract archive and add bitcoin-25.0/bin to PATH - bitcoind and bitcoin-cli should be available on PATH for this Demo to run a RegTest node
3. Install python3, python3-pip / pip3 and jq. eg. `apt install python3 python3-pip jq`
4. Install **cryptos** module for python. eg. `pip3 install cryptos`
5. Clone or Checkout this repository - `git clone <url>`

## Proof of Concept Implementation - Setup (Docker)

1. Install Docker if not already installed - https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04
2. Clone or Checkout this repository - `git clone https://github.com/VaultCoinHQ/SmartVaults.git`
3. Change working directory to cloned repo directory - `cd SmartVaults`
4. Important - Customize Dockerfile included in the repo to download appropriate bitcoin binary archive for the architecture and platform you are working on
5. Build Image - `sudo docker build -t smartvaults .`
6. Run Image - `sudo docker run -it smartvaults`
7. Delete Image - `sudo docker images` to get `<IMAGE ID>` and `sudo docker rmi -f <IMAGE ID>` to remove the image once you are done exploring this demo.

## Proof of Concept Implementation - Demo

1. Open a shell/cmd in the project/repository's root directory. (SmartVaults)
2. Inspect and run `./SmartVault.Demo.sh` for an interactive demo of Hybrid Custody using Layer 2 Smart Vaults™ (Participants: User & Sentinel).
3. Inspect and run `./SmartVault.Demo.Setup_and_Spend_Using_Option_1.sh` to understand Smart Vault™ setup (Participants: User & Sentinel) and termination/spend using Option 1 which requires only User's private-key. This path mimics Self-Custody.
4. Inspect and run `./SmartVault.Demo.Setup_and_Recovery_Using_Option_2.sh` to understand Smart Vault™ setup (Participants: User & Sentinel) and recovery using Option 2 which requires only Sentinel's private-key. Useful when User has lost his private-keys. Option 2 has lower priority than Option 1. So User can override any attempt by Sentinel to unlock the Smart Vault™ without his consent.
5. Inspect and run `./SmartVault.Demo.Setup_and_Recovery_Using_Option_3.sh` to understand Smart Vault™ setup (Participants: User & Sentinel) and recovery using Option 3 which requires both User's and Sentinel's private-keys. Option 3 has higher priority than Option 1 and Option 2. Useful when either User's or Sentinel's private-key is presumed stolen and was used to unlock the Smart Vault™. 
6. All demos are designed to run on a Bitcoin RegTest network and create a fresh RegTest node to communicate with. See SmartVault.Demo.Initialize_RegTest_Network.sh (executed inside above demo scripts) for more details.
7. All demos follow the same Smart Vault™ setup process with "User" and "Sentinel" as paritcipants. See SmartVault.Demo.Setup.sh (executed inside above demo scripts) for more info.
8. All demos write detailed logs to respective log files in the `logs` folder and you can go through sample logs from the above demos in the `logs` folder to get an idea about how these demos work even before you run them on your machine.

## Legal Notice

### Proprietary Technology Demonstration Repository

This repository contains source code and other materials solely for the purpose of demonstrating a proprietary technology protected by patents. The technology described herein is confidential and proprietary.

### Restrictions

1. **No Copying or Modification**: You may not copy, modify, or create derivative works based on the code provided in this repository.

2. **No Publication or Distribution**: You may not publish, distribute, or otherwise make the code publicly available.

3. **No Reverse Engineering**: Reverse engineering, decompiling, or disassembling any part of the code is strictly prohibited.

### Disclaimer

The code in this repository is provided "as is" without any warranties or guarantees. The owner of this repository shall not be liable for any damages arising from the use of this code. It is for demonstration purposes only.

### Patents

The technology demonstrated in this repository is protected by one or more patents. Any unauthorized use, reproduction, or distribution may result in legal action.

More Info: https://www.coinvault.tech/patents/

By accessing or using this repository, you agree to abide by these terms and conditions. If you have any questions or need further clarification, please contact connect@coinvault.tech.

