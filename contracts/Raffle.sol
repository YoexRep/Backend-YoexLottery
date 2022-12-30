//paso del contrato

/*
   1-- Preparar el contrato Raffle
   2-- Enter the lottery(pago los 5 dolares y eligo un numero)
    3-- Pick a random winner (verifiably random)
    4-- Winner to be selected every X minutes -> completly automate
    5-- Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";


error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffeState);

/** 
 *@title  Proyecto de lotteria decentralizada
 * @author yoel torres
 * @notice Este contrato es para crear un proyecto personal de lotteria decentralizada
 * @dev este implementa chainlink coordinator y chainlik keeper
 * 
 * 
 * 
 */



//Implemento estas 2 interfaces.
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /*Type declarations */

    enum RaffleState {
        OPEN,
        CALCULATING
    } //uint256 0= OPEN, 1= CALCULATING

    //state Variables
    uint256 private immutable i_entranceFee;
    address[] private s_players;
    uint256[] private s_numeros_jugados;
    address[] private s_players_winners;

    //Mapeo las direcciones con los numeros jugado de cada direccion
     mapping(address => uint256) private s_addressToNumeroJugado;


    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_suscripcionId;
    uint16 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;

    //Lottery Variables

    
    //Variable creada del tipo de dato Enum
    RaffleState private s_rafflestate;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    uint256 private cantidadGanadaPorJugador;
     uint256 private numeroGanador;

    /*Events */
    //Es una buena practica que los eventos tenga el nombre de la funcion que van a usar, pero invertido en este caso enterRaffle, tiene un evento llamado raffleEnter
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 suscripcionId,
        uint16 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane; // Cuanto estas dispuesto a pagar
        i_suscripcionId = suscripcionId; //ID de la suscripcion de nuestro contrato a chainlink
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate = RaffleState.OPEN; // Inicializo la variable con enum
        s_lastTimeStamp = block.timestamp;
    i_interval = interval;
    
    }

    function enterRaffle(uint256 numeroJugado) public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }

        //Valido si la raffle no esta abierta, de lo contrario la reyecto
        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        //Obtengo la direccion del jugador
        s_players.push(payable(msg.sender));
        s_numeros_jugados.push(numeroJugado);
    //Ingreso al mapeo de direccion el numero jugado por la direccion
        s_addressToNumeroJugado[msg.sender] += numeroJugado;

        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev Esta la funcion que chainlink keeper nodes llaman para ver si 'Upkeepneed' retorna un true.
     * necesita devolver un true, para que me genere otro numero aleatorio.
     *
     * Se debe de cumplir lo siguiente para que sea true:
     *
     * 1- El tiempo de intervalo deberia pasar.
     * 2- La loteria deberia tener al menos 1 jugador,  y tener algunos eth
     * 3- Nuestra subscricion tiene link de fondos
     * 4- La loteria deberia esta en estado "abierto", si queremos participar de esta loteria.
     *
     */


    //Este me valida si se cumple todas las condiciones para poder hacer la solicitud de un nuevo ganador. 2-- en llamar
    function checkUpkeep(bytes memory /*checkData*/) public override returns(bool upkeepNeeded, bytes memory /* perfomData*/){

        bool isOpen = RaffleState.OPEN == s_rafflestate;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);

       
        //return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    //Este metodo se queda observado por el keeper, y cuando se invoca, llama a checkUpKeep, el cual si cumple todas las condiciones, emite un evento con el idrequest, el cual pide un numero de forma random
    function performUpkeep( bytes calldata /*perfomData*/) external override {
        //Request the random number
        //Once we get it, do something with it
        //2 transaction process

        (bool upkeepNeeded, /*Aqui va el return del perfomdata */) = checkUpkeep(""); 

            //si no se cumple la condicion devuelta por el checkupkeep
            if(!upkeepNeeded){
                    revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_rafflestate));
            }



        s_rafflestate = RaffleState.CALCULATING; // actualizo mi valor de s_raffle para evitar que alguien entre mientras se este calculando
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_suscripcionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }


    

   
//Funcion para obtener un numero random

    function fulfillRandomWords(
        uint256 /* requestId*/,
        uint256[] memory randomWords
    ) internal override {
        //Obtener un numero random del 0 al 99
        uint256 condicional = randomWords[0] % 10; //obtengo un condicional de 1 digito, sacado del primer numero dado por chainlink

        
        /*
            Obtener el numero ganador basado en el condicional sacado del primer numero dado por chainlink
            Si es menor que 2, obtenego un numero de un solo digito, usando el 2 numero random dado por chainlink,
            si es mayor que 2 obtengo un numero con 2 digitios sacado del numero random dado por chainlink
        */
          if(condicional < 2){
               numeroGanador = randomWords[1] % 10; //Obtengo un numero solo con 1 digito
          }else{
             numeroGanador = randomWords[1] % 100; //Obtengo un numero con 2 digitos
          }  

   

         //Receteo el array  de ganadores cada vez que busco un nuevo numero
        s_players_winners = new address payable[](0);
   

        //lo paso a memory para que gaste menos recorrerlo
        address[] memory players = s_players;
      

        for (
            uint256 playerIndex = 0;
            playerIndex < players.length;
            playerIndex++
        ) {

            //Obtengo la direccion del jugador y luego busco el numero que jugo
            address addressPlayer = players[playerIndex];

            uint256 numeroJugado = getNumeroJugadoPorAddress(addressPlayer);

            if(numeroJugado == numeroGanador){
                    s_players_winners.push(addressPlayer);
            }
        }
        
         //lo paso a memory los ganadores para que gaste menos recorrerlo
        address[] memory  players_winner = s_players_winners;

        //Obtengo la cantidad que se le enviara a cada jugador
        cantidadGanadaPorJugador = address(this).balance /players_winner.length;


         for (
            uint256 playerIndex = 0;
            playerIndex < players_winner.length;
            playerIndex++
        ) {

            //Obtengo la direccion del jugador ganador y luego busco el numero que jugo
            address payable addressPlayer_winner = payable(players_winner[playerIndex]);
           
       
        
            (bool success, ) = addressPlayer_winner.call{value: cantidadGanadaPorJugador}(""); //le envio el dinero al ganador

         if (!success) {
            revert Raffle__TransferFailed(); // Si no funciona lo revierto
        } 

        emit WinnerPicked(addressPlayer_winner); 
          
        }
        
     

        

        //Despues de sacar un ganador, necesito resetear mi arreglo.
        s_players = new address payable[](0);
        
        s_lastTimeStamp = block.timestamp;
         s_rafflestate = RaffleState.OPEN; // aqui vuelvo a poner la variable en open
       
    }

    /*View / Pure functions */
 

     function getNumerosJugados() public view returns (uint256[] memory) {
        return s_numeros_jugados;
    }


     function getNumeroGanador() public view returns (uint256) {
        return numeroGanador;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_rafflestate;
    }

//Este get es pure, ya que estoy leyendo una constante, por lo que no tengo que hacerla una view
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getListadoJugadores() public view returns (address[] memory) {
        return s_players;
    }

      function getListadoDeGanadores() public view returns (address[] memory) {
        return s_players_winners;
    }

    

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    //Esta tambie lee una constante
    function getRequestConfirmation() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumeroJugadoPorAddress(address direccionJugador)
        public
        view
        returns (uint256)
    {
        return s_addressToNumeroJugado[direccionJugador];
    }

     function getCantidadGanada() public view returns (uint256) {
        return cantidadGanadaPorJugador;
    }

    

     receive() external payable {}

    fallback() external payable {}

}
