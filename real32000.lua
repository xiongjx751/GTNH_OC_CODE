component = require("component")
sides = require("sides")

rs_switch_side = sides.east
rs_reactor_side = sides.west

tp_reactor_side = sides.south
tp_clean_cell_side = sides.down
tp_dirty_cell_side = sides.west
tp_fuel_side = sides.up
tp_waste_side = sides.north

damage_threshold = 95
time_to_produce_coolantcell = 8
log_duration_in_minutes = 0.5

coolantcell_name = "gregtech:gt.60k_Helium_Coolantcell"
fuel_name = "gregtech:gt.reactorUraniumQuad"
waste_name = "IC2:reactorUraniumQuaddepleted"

rs = component.redstone
bf = component.gt_machine
tp = component.transposer

last_log_time = os.clock()

function switch_on()
    rs.setOutput(rs_reactor_side, 15)
end

function switch_off()
    rs.setOutput(rs_reactor_side, 0)
end

function wait(msg, tim)
    if tim == nil then
        tim = 1
    end
    if msg ~= nil then
        print(msg)
    end
    switch_off()
    os.sleep(tim)
    switch_on()
end

function get_energy_level()
    return bf.getEUStored() / bf.getEUMaxStored()
end

function get_first_item_slot(side)
    for idx, item in pairs(tp.getAllStacks(side).getAll()) do
        if item.name ~= nil then
            return idx + 1
        end
    end
end

function do_replace_cell(slot)
    while true do 
        from_slot = get_first_item_slot(tp_clean_cell_side)
        if from_slot == nil then
            wait("No clean coolantcell, waiting ...", time_to_produce_coolantcell)
        else
            tp.transferItem(tp_reactor_side, tp_dirty_cell_side, 1, slot)
            tp.transferItem(tp_clean_cell_side, tp_reactor_side, 1, from_slot, slot)
            return
        end
    end
end

function do_replace_fuel(slot) 
    from_slot = get_first_item_slot(tp_fuel_side)
    if from_slot == nil then
        print("Warning: No Fuel")
    else
        tp.transferItem(tp_reactor_side, tp_waste_side, 1, slot)
        tp.transferItem(tp_fuel_side, tp_reactor_side, 1, from_slot, slot)
    end
end

function fmtEU(x)
    tail = ""
    if x > 1000 then
        x = x / 1000
        tail = "K"
    end
    if x > 1000 then
        x = x / 1000
        tail = "M"
    end
    if x > 1000 then
        x = x / 1000
        tail = "G"
    end
    if x > 1000 then
        x = x / 1000
        tail = "T"
    end
    return string.format("%.1f%s", x, tail)
end

switch_on()

lstEU = bf.getEUStored()

while true do

    if rs.getInput(rs_switch_side) == 0 then
        switch_off()
        print("Reactor Stoppend.")
        break
    end

    if os.clock() - last_log_time >= log_duration_in_minutes then
        curEU = bf.getEUStored()
        print(string.format("%sEU / %sEU, %.3f%% charged, in %sEU/t", 
            fmtEU(curEU), 
            fmtEU(bf.getEUMaxStored()), 
            get_energy_level() * 100,
            fmtEU((curEU - lstEU) / (os.clock() - last_log_time) / 60 / 20)
        ))
        last_log_time = os.clock()
        lstEU = curEU
    end

    if get_energy_level() > 0.98 then
        wait("Energy buffer almost full, sleep for a while.", 30)
    end

    for idx, item in pairs(tp.getAllStacks(tp_reactor_side).getAll()) do
        if item.name ~= nil then
            if item.name == coolantcell_name then
                if item.damage >= damage_threshold then
                    do_replace_cell(idx + 1)
                end
            elseif item.name == waste_name then
                do_replace_fuel(idx + 1)
            end
        end
    end
end
