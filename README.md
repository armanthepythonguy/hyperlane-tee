# Hyperlane TEE

![hypertee](https://github.com/user-attachments/assets/77d944e8-8df8-4fa3-889e-8c1a7dee1382)


Currently, Hyperlane employs a multisignature-based consensus mechanism to approve messages across chains. However, this approach introduces potential vulnerabilities, such as the risk of Sybil attacks. Additionally, maintaining transparency requires deploying multiple validators, which can increase complexity and operational overhead.

To address these challenges, we propose leveraging Trusted Execution Environments (TEE). A lightweight validator code will be executed within the TEE, continuously monitoring dispatch events on the origin chain. For each message, the TEE will generate secure proofs, which can be verified by a TEE-based Interchain Security Module (ISM) before the message is delivered to the destination chain.

This approach enhances security, mitigates the risk of Sybil attacks, and streamlines the validation process while ensuring transparency.


We have implemented our TEE validator using Phala. The validator utilizes web3.py to listen for dispatch events emitted by the mailbox on the origin chain. These messages are batched, and a single TEE proof is generated for the entire batch. The payload of the proof includes the message_id associated with the messages in the batch.

The TEE proof is then submitted to the TEE-based Interchain Security Module (ISM), where it undergoes verification. This process ensures the proof originates from the correct binary file and validates that the payload matches the expected content. For hashing, we utilize SHA-384 and SHA-512, which are native to Phala.

Subsequently, the relayer queries the TEE ISM to verify whether the proof was successfully submitted for the corresponding message. If the verification is successful, an approval is issued, enabling the mailbox to deliver the message.
