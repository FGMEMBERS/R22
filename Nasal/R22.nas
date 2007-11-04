var RPM_arm=props.globals.getNode("/instrumentation/alerts/rpm",1);
var ViewNum=0;
var EyePoint = 0;
var last_time = 0;
var GPS = 0.002222;  ### avg cruise = 8 gph
var Fuel_Density=6.72;
Fuel_Level= props.globals.getNode("/consumables/fuel/tank/level-gal_us",1);
Fuel_LBS= props.globals.getNode("/consumables/fuel/tank/level-lbs",1);
NoFuel=props.globals.getNode("/engines/engine/out-of-fuel",1);
var FDM = 0;

strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/R22/lighting/strobe-state", [0.05, 1.50], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/R22/lighting/beacon-state", [1.0, 1.0], beacon_switch);

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    Fuel_Density=props.globals.getNode("/consumables/fuel/tank/density-ppg").getValue();
    setprop("/instrumentation/clock/flight-meter-hour",0);
    RPM_arm.setBoolValue(0);
    print("Systems ... Check");
    settimer(update_systems,2);
});

setlistener("/sim/signals/reinit", func {
    RPM_arm.setBoolValue(0);
});


setlistener("/gear/gear[1]/wow", func {
    if(cmdarg().getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
});

setlistener("/engines/engine/out-of-fuel", func {
    var nofuel = cmdarg().getBoolValue();
    if(nofuel){
        props.globals.getNode("/engines/engine/running").setBoolValue(0);
    }
});

flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

update_fuel = func{
    var amnt = arg[0] * GPS;
    var lvl = Fuel_Level.getValue();
    Fuel_Level.setDoubleValue(lvl-amnt);
    Fuel_LBS.setDoubleValue(lvl * Fuel_Density);
    if(lvl < 0.2){
        if(!NoFuel.getBoolValue()){
            NoFuel.setBoolValue(1);
        }
    }

}

update_systems = func {
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;
        update_fuel(dt);
flight_meter();
if(!RPM_arm.getBoolValue()){
if(getprop("/rotors/main/rpm") > 525)RPM_arm.setBoolValue(1);
}
settimer(update_systems,0);
}


