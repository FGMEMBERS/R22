var RPM_arm=props.globals.getNode("/instrumentation/alerts/rpm",1);
var ViewNum=0;
var EyePoint = 0;
var last_time = 0;
var start_timer=0;
var GPS = 0.002222;  ### avg cruise = 8 gph
var Fuel_Density=6.0;
Fuel1_Level= props.globals.getNode("/consumables/fuel/tank/level-gal_us",1);
Fuel1_LBS= props.globals.getNode("/consumables/fuel/tank/level-lbs",1);
Fuel2_Level= props.globals.getNode("/consumables/fuel/tank[1]/level-gal_us",1);
Fuel2_LBS= props.globals.getNode("/consumables/fuel/tank[1]/level-lbs",1);
TotalFuelG=props.globals.getNode("/consumables/fuel/total-fuel-gals",1);
TotalFuelP=props.globals.getNode("/consumables/fuel/total-fuel-lbs",1);
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
    if(nofuel)kill_engine();
});

setlistener("/controls/electric/key", func {
    var key = cmdarg().getValue();
    if(key == 0)kill_engine();
});

flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

kill_engine=func{
        setprop("/controls/engines/engine/magnetos",0);
        setprop("/engines/engine/running",0);
        start_timer=0;
}

update_fuel = func{
    var amnt = arg[0] * GPS;
    amnt = amnt * 0.5;
    var lvl = Fuel1_Level.getValue();
    var lvl2 = Fuel2_Level.getValue();
    lvl = lvl-amnt;
    if(lvl2 > 0){lvl2 = lvl2-amnt;
    }else{
    lvl = lvl-amnt;
    }
    if(lvl < 0.0)lvl = 0.0;
    if(lvl2 < 0.0)lvl2 = 0.0;
    var ttl = lvl+lvl2;
    Fuel1_Level.setDoubleValue(lvl);
    Fuel1_LBS.setDoubleValue(lvl * Fuel_Density);
    Fuel2_Level.setDoubleValue(lvl2);
    Fuel2_LBS.setDoubleValue(lvl2 * Fuel_Density);
    TotalFuelG.setDoubleValue(ttl);
    TotalFuelP.setDoubleValue(ttl * Fuel_Density);
    if(ttl < 0.2){
        if(!NoFuel.getBoolValue()){
            NoFuel.setBoolValue(1);
        }
    }
}

update_systems = func {
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;
    if(getprop("controls/engines/engine/magnetos") > 0)update_fuel(dt);
flight_meter();
if(!RPM_arm.getBoolValue()){
if(getprop("/rotors/main/rpm") > 525)RPM_arm.setBoolValue(1);
}
if(getprop("/controls/engines/engine/starter")){
    if(!getprop("/engines/engine/running")){
    start_timer +=1;
    }else{start_timer = 0;}
}
if(start_timer > 50){setprop("/engines/engine/running",1);
    start_timer = 0;
    }
if(getprop("/controls/engines/engine/clutch")){
    if(getprop("/engines/engine/running")){
    setprop("/controls/engines/engine/magnetos",1);
    }
}else{
    setprop("/controls/engines/engine/magnetos",0);
    }

if(!getprop("/engines/engine/running"))setprop("/controls/engines/engine/magnetos",0);
settimer(update_systems,0);
}


