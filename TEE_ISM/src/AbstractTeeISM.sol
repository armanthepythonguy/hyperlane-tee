// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Sha2Ext } from "./Sha2Ext.sol";
import {BELE} from "./BELE.sol";
import {BytesUtils} from "./BytesUtils.sol";
import {LibString} from "./LibString.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";
import "@hyperlane-xyz/core/contracts/libs/Message.sol";

contract AbstractTEEISM is IInterchainSecurityModule {
    using LibString for bytes;
    using BytesUtils for bytes;
    uint16 constant HEADER_LENGTH = 48;
    uint16 constant TD_REPORT10_LENGTH = 584;
    address owner;

    struct Header {
        uint16 version;
        bytes2 attestationKeyType;
        bytes4 teeType;
        bytes2 qeSvn;
        bytes2 pceSvn;
        bytes16 qeVendorId;
        bytes20 userData;
    }

    struct TD10ReportBody {
        bytes16 teeTcbSvn;
        bytes mrSeam; // 48 bytes
        bytes mrsignerSeam; // 48 bytes
        bytes8 seamAttributes;
        bytes8 tdAttributes;
        bytes8 xFAM;
        bytes mrTd; // 48 bytes
        bytes mrConfigId; // 48 bytes
        bytes mrOwner; // 48 bytes
        bytes mrOwnerConfig; // 48 bytes
        bytes rtMr0; // 48 bytes
        bytes rtMr1; // 48 nytes
        bytes rtMr2; // 48 bytes
        bytes rtMr3; // 48 bytes
        bytes reportData; // 64 bytes
    }

    mapping (bytes32 => bytes) attestations;

    constructor(){
        owner = msg.sender;
    }

    function submitProofs(bytes calldata _proof, bytes32 _mid) external{
        require(msg.sender==owner, "Only TEE can submit proofs");
        attestations[_mid] = _proof;
    }

    function getHashed(
        bytes memory message
    ) public pure returns (bytes memory) {
        (bytes32 a, bytes16 b) = Sha2Ext.sha384(message);
        bytes memory c = abi.encodePacked(a, b);
        (bytes32 d, bytes32 e) = Sha2Ext.sha512(c);
        return (abi.encodePacked(d, e));
    }

    function getPayload(bytes calldata quote) public returns (bytes memory) {
        uint256 offset = HEADER_LENGTH + TD_REPORT10_LENGTH;
        bytes memory rawData = quote[HEADER_LENGTH:offset];
        TD10ReportBody memory tdReport = parseTD10ReportBody(rawData);
        return (tdReport.reportData);
    }

    function getHeader(
        bytes calldata rawQuote
    ) public pure returns (Header memory header) {
        bytes2 attestationKeyType = bytes2(rawQuote[2:4]);
        bytes2 qeSvn = bytes2(rawQuote[8:10]);
        bytes2 pceSvn = bytes2(rawQuote[10:12]);
        bytes16 qeVendorId = bytes16(rawQuote[12:28]);

        header = Header({
            version: uint16(BELE.leBytesToBeUint(rawQuote[0:2])),
            attestationKeyType: attestationKeyType,
            teeType: bytes4(uint32(BELE.leBytesToBeUint(rawQuote[4:8]))),
            qeSvn: qeSvn,
            pceSvn: pceSvn,
            qeVendorId: qeVendorId,
            userData: bytes20(rawQuote[28:48])
        });
    }

    function parseTD10ReportBody(
        bytes memory reportBytes
    ) internal pure returns (TD10ReportBody memory report) {
        report.teeTcbSvn = bytes16(reportBytes.substring(0, 16));
        report.mrSeam = reportBytes.substring(16, 48);
        report.mrsignerSeam = reportBytes.substring(64, 48);
        report.seamAttributes = bytes8(
            uint64(BELE.leBytesToBeUint(reportBytes.substring(112, 8)))
        );
        report.tdAttributes = bytes8(
            uint64(BELE.leBytesToBeUint(reportBytes.substring(120, 8)))
        );
        report.xFAM = bytes8(
            uint64(BELE.leBytesToBeUint(reportBytes.substring(128, 8)))
        );
        report.mrTd = reportBytes.substring(136, 48);
        report.mrConfigId = reportBytes.substring(184, 48);
        report.mrOwner = reportBytes.substring(232, 48);
        report.mrOwnerConfig = reportBytes.substring(280, 48);
        report.rtMr0 = reportBytes.substring(328, 48);
        report.rtMr1 = reportBytes.substring(376, 48);
        report.rtMr2 = reportBytes.substring(424, 48);
        report.rtMr3 = reportBytes.substring(472, 48);
        report.reportData = reportBytes.substring(520, 64);
    }

    function moduleType() external view override returns (uint8) {
        IInterchainSecurityModule.Types.ROUTING;
    }

    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external override returns (bool) {
        bytes32 id = Message.id(_message);
        bytes memory hashed = getHashed(abi.encode(id));
        require(attestations[id].length!=0, "Proof not yet uploaded !!!");
        bytes memory quote = attestations[id];
        bytes memory payload = getPayload(quote);
        if(BytesUtils.equals(hashed, payload)){
            return true;
        }else{
            return false;
        }
    }
}
