// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**

2. REPETIBLE CON LÍMITE, PREMIO POR REFERIDO</u>

- El usuario puede participar en el airdrop una vez por día 
  hasta un límite de 10 veces - done 
- Si un usuario participa del airdrop a raíz de haber sido referido, el 
  que refirió gana 3 días adicionales para poder participar - done
- El contrato Airdrop mantiene los tokens para repartir (no llama al `mint` ) - done 
- El contrato Airdrop tiene que verificar que el `totalSupply` del token no 
  sobrepase el millón
- El método `participateInAirdrop` le permite participar por un número random de
  tokens de 1000 - 5000 tokens - done
 */

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IIIToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropTWOoooo is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address addressToken; // = [reemplazar por el address token cuando esta publicado]
    IIIToken token = IIIToken(addressToken);

    struct Participante {
        address account;
        uint256 participaciones; // cantidad de veces que participo
        uint256 limiteParticipaciones;
        uint256 ultimaVezQueParticipo; // timestamp de la ultima vez
    }
    mapping(address => Participante) public participantes;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function participateInAirdrop(address _personaQueTeRefirio) public {
        // validar si el usuario es nuevo o no
        // usuario nuevo
        if (participantes[msg.sender].account == address(0)) {
            // se guarda esta informacion cuando el participante es nuevo
            Participante memory participante = Participante({
                account: msg.sender,
                participaciones: 1,
                limiteParticipaciones: 10,
                ultimaVezQueParticipo: block.timestamp
            });
            participantes[msg.sender] = participante;
        } else {
            // vefificar que no sobrepaso su limite de participaciones
            Participante storage _participante = participantes[msg.sender];
            require(
                _participante.participaciones <=
                    _participante.limiteParticipaciones,
                "Sobrepaso su limite de participaciones"
            );
            _participante.participaciones++;

            // timeStamp actual se compara con el ultimaVezQueParticipo
            // si timeStamp actual - ultimaVezQueParticipo > 1 dia => ya paso un dia
            // si timeStamp actual - ultimaVezQueParticipo < 1 dia => esta dentro del dia
            // si timeStamp actual < ultimaVezQueParticipo + 1 dia => esta dentro del dia
            // si timeStamp actual > ultimaVezQueParticipo + 1 dia => ya paso mas de un dia
            // block.timestamp =< timestamp actual
            // 1 days => 60 * 60 * 24
            require(
                _participante.ultimaVezQueParticipo + 1 days > block.timestamp,
                "Aun esta dentro del dia"
            );
            _participante.ultimaVezQueParticipo = block.timestamp;
        }

        uint256 tokensGanados = _getRandomEntre1000y5000();
        // sumando el premio del usuario, no debe pasar el millon de tokens
        uint256 totalSupplyMasPremio = token.totalSupply() + tokensGanados;
        require(
            totalSupplyMasPremio <= 10**6 * 10**18,
            "Sobrepaso el millon de tokens en supply"
        );

        // address(this) => devuelve el address del smart contract actual
        require(
            token.balanceOf(address(this)) >= tokensGanados,
            "Airdrop SC no tiene tokens"
        );

        token.transfer(msg.sender, tokensGanados);

        if (
            _personaQueTeRefirio != address(0) &&
            _personaQueTeRefirio != msg.sender
        ) {
            participantes[_personaQueTeRefirio].limiteParticipaciones += 3;
        }
    }

    function deliverInBatch(address[] memory accounts, uint256[] memory amounts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _length = accounts.length;
        for (uint256 i = 0; i < _length; i++) {
            address _acc = accounts[i];
            token.transfer(_acc, amounts[i]);
        }
    }

    function _getRandomEntre1000y5000() internal view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                4000) +
            1000 +
            1;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
