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



var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();

setlistener("/sim/signals/fdm-initialized", func {
    Fuel_Density=props.globals.getNode("/consumables/fuel/tank/density-ppg").getValue();
    setprop("/instrumentation/clock/flight-meter-hour",0);
    RPM_arm.setBoolValue(0);
    print("Systems ... Check");
    settimer(update_systems,2);
    setprop("sim/model/sound/volume", 0.5);
});

setlistener("/sim/signals/reinit", func {
    RPM_arm.setBoolValue(0);
});

setlistener("/sim/current-view/view-number", func(vw) {
    var nm = vw.getValue();
    setprop("sim/model/sound/volume", 1.0);
    if(nm == 0 or nm == 7)setprop("sim/model/sound/volume", 0.5);
},1,0);

setlistener("/gear/gear[1]/wow", func(gr) {
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/engines/engine/out-of-fuel", func(fl) {
    var nofuel = fl.getBoolValue();
    if(nofuel)kill_engine();
},0,0);

setlistener("/engines/engine/running", func(eng){
    var running = eng.getBoolValue();
    if(running){
        interpolate("/engines/engine/rpm", 2500, 2);
        }else{
        interpolate("/engines/engine/rpm", 0, 2);
        }
},1,0);

setlistener("/controls/electric/key", func(ky){
    var key = ky.getValue();
    if(key > 0)setprop("/controls/engines/engine/magnetos",key);
    if(key == 0)kill_engine();
},0,0);

setlistener("/sim/crashed", func(ko) {
    if(ko.getValue()){
    kill_engine();
    setprop("/rotors/main/rpm",0);
    setprop("/rotors/tail/rpm",0);
    }
},0,0);

flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

kill_engine=func{
        setprop("/controls/engines/engine/magnetos",0);
        setprop("/engines/engine/clutch-engaged",0);
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
    if(getprop("engines/engine/running"))update_fuel(dt);
flight_meter();
if(!RPM_arm.getBoolValue()){
if(getprop("/rotors/main/rpm") > 525)RPM_arm.setBoolValue(1);
}

if(getprop("/systems/electrical/outputs/starter") > 6.0){
    if(getprop("/controls/electric/key") > 2)setprop("/engines/engine/cranking",1);
    }else{
    setprop("/engines/engine/cranking",0);
    }

if(getprop("/engines/engine/cranking") != 0){
    if(!getprop("/engines/engine/running")){
    start_timer +=1;
    }else{start_timer = 0;}
}
if(start_timer > 50){setprop("/engines/engine/running",1);
    start_timer = 0;
    }
if(getprop("/controls/engines/engine/clutch")){
    if(getprop("/engines/engine/running")){
    setprop("/engines/engine/clutch-engaged",1);
    }else{
    setprop("/engines/engine/clutch-engaged",0);
    }
}

if(!getprop("/engines/engine/running"))setprop("/engines/engine/clutch-engaged",0);
settimer(update_systems,0);
}


