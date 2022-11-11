// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract plantProtection{

        uint orderid;            

        address FarmerAddress;         
        uint[2] farmlandLocation;
        uint area;                
        uint[2] timeWindow;       
        uint pesticideType;       
        uint[2] temperatureWindow;
        uint   q;                

        uint droneID;        
        address droneAddress; 

        enum  orderState {
            Waiting, Heading, Arrived, Spraying,Sprayed, Completed, Assessed
        }
        orderState public state;
        uint   createOrderTime;
        uint   updataOrderTime;

        uint[][] GPSsensor;      

        uint[] TempSensor;        
        uint[] PressureSensor;   
        uint   actualArrivedTime;
        uint   actualStartTime;  
        uint   actualEndTime;     
        uint[][] SprayingGPS;     
        uint   money;             
        uint   PayTime;
        
        uint   SatisfactionLevel;
        uint   AssessmentTime;          


    modifier OnlyDrone(){  //only Drone
        require(msg.sender == droneAddress);
        _;
    }
    modifier OnlyFarmer(){//only Farmer
        require(msg.sender == FarmerAddress);
        _;
    }
    modifier costs(){  
        require(msg.value == money);
        _;
    }

    // event
    event deploySuccessful(string msg);            
    event waitingToGo(string msg);
    event HeadingMsg(string msg,address Drone);     
    event ArrivedMsg(string msg,address Drone);       
    event SprayingMsg(string msg,address Drone);      
    event PayMoneyMsg(string msg,address Drone);      
    event CompletedMsg(string msg,address Farmer);
    event AssessmentMsg(string msg,address Farmer);  

    event deployNewSuccessful(string msg); 
    event updateSuccessful(string msg); 


   function  Deploy(uint[] memory _Order, address _FarmerAddress, address _droneAddress) public{
    //_Order=[_OrderID, _farmlandLocX, _farmlandLocY, _area, _ET, _LT, _pesticideType,_LTemperature, _HTemperature, _q, _droneID]  _Farmeraddress, _droneAddress

        orderid = _Order[0];                            
        farmlandLocation = [_Order[1],_Order[2]];      
        area = _Order[3];                              
        timeWindow = [_Order[4],_Order[5]];            
        pesticideType = _Order[6];                      
        temperatureWindow = [_Order[7],_Order[8]];     
        q = _Order[9];                                       
        droneID = _Order[10];                            
        
        FarmerAddress = _FarmerAddress;  
        droneAddress = _droneAddress;    

        state = orderState.Waiting;      
        updataOrderTime = block.timestamp; 

        emit deploySuccessful("The order has been created and is waiting for service");
        emit waitingToGo("The order is waiting to go");

    }

    function DeployNew(uint[] memory _Order, address _FarmerAddress, address _droneAddress) public{
      //_Order=[_OrderID, _farmlandLocX, _farmlandLocY, _area, _ET, _LT, _pesticideType,_LTemperature, _HTemperature, _q, _droneID]  _Farmeraddress, _droneAddress

        orderid = _Order[0];                          
        farmlandLocation = [_Order[1],_Order[2]];     
        area = _Order[3];                             
        timeWindow = [_Order[4],_Order[5]];            
        pesticideType = _Order[6];                    
        temperatureWindow = [_Order[7],_Order[8]];      
        q = _Order[9];                                      
        droneID = _Order[10];                           
        
        FarmerAddress = _FarmerAddress; 
        droneAddress = _droneAddress;     

        state = orderState.Waiting;        
        createOrderTime = block.timestamp;  

        emit deployNewSuccessful("This order information has been updated");
        emit updateSuccessful("This order information has been updated");
        emit waitingToGo("The order is waiting to go");

    }

    function Heading(uint[] memory _GPSdata) OnlyDrone public {
        // _GPSdata = [_droneID,_GPSsensorX,_GPSsensorY] 
        require(droneID == _GPSdata[0]);
        state = orderState.Heading;                 
        GPSsensor.push([_GPSdata[1],_GPSdata[2]]);

        emit HeadingMsg("The drone is heading.",droneAddress);
    }

    function DroneArrived(uint[] memory _GPSdata) OnlyDrone public{
        // _GPSdata = [_droneID,_GPSsensorX,_GPSsensorY,_dronePressure]
        require(state == orderState.Heading);
        state = orderState.Arrived; 
        GPSsensor.push([_GPSdata[1],_GPSdata[2]]); 
        actualArrivedTime = block.timestamp;       
        PressureSensor.push(_GPSdata[3]); 

        emit ArrivedMsg("The drone has been arrived.",droneAddress);
    }

    function SwitchOn() OnlyDrone public {
        if(state == orderState.Arrived){
            state = orderState.Spraying;      
            actualStartTime = block.timestamp;

            emit SprayingMsg("The drone is spraying pesticides.",droneAddress);
        }
    }

    function Spraying(uint[] memory _GPSdata) OnlyDrone public{
        // _GPSdata = [_droneID,_GPSsensorX,_GPSsensorY,_Tempture]
        if(state == orderState.Spraying){
            SprayingGPS.push([_GPSdata[1],_GPSdata[2]]); 
            TempSensor.push(_GPSdata[3]);                

            emit SprayingMsg("The drone is spraying pesticides.",droneAddress);
        }
    }

    function SwitchOff(uint[] memory _dronePressure) OnlyDrone public{
        // _dronePressure = [_droneID,_dronePressure] 
        if(state == orderState.Spraying){
            PressureSensor.push(_dronePressure[1]); 
            actualEndTime = block.timestamp;      
            money = 50;                      
            state = orderState.Sprayed;           

            emit PayMoneyMsg("The drone spraying is complete.",droneAddress);
        }
    }

    function Pay() OnlyFarmer costs public payable{
        require(state == orderState.Sprayed); 
        payable(droneAddress).transfer(msg.value);     
        PayTime = block.timestamp;                   
        state = orderState.Completed;                

        emit CompletedMsg("The order has been completed.",FarmerAddress);
    }

    function Assessment(uint _satisfaction) OnlyFarmer public{
        require(state == orderState.Completed); 
        SatisfactionLevel = _satisfaction;    
        AssessmentTime = block.timestamp;                  
        state = orderState.Assessed;             

        emit AssessmentMsg("The order has been assessed.",FarmerAddress);
    }
}