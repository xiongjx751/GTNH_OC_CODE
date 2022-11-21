component = require("component")
sides = require("sides")

reactor_direction = sides.west
dirty_cell_direction = sides.east
clean_cell_direction = sides.north
fuel_waste_direction = sides.up
fuel_direction = sides.down
rs_side = sides.west
cell_name = "60k_NaK"
fuel_waste_name = "depleted"
log_duration = 60
eu_t_full = 43600
battery_max_sotrage = 6400000
num_batteries = 4

tsp = component.transposer
rs = component.redstone
bf = component.gt_batterybuffer

function get_empty_idx(side) 
    while true do
        for idx, item in pairs(tsp.getAllStacks(side).getAll()) do
            if item.name == nil then
                return idx
            end
        end
        print("waiting for empty space in dirty cell chest")
        os.sleep(8)
    end
end

function get_valid_idx(side) 
    for idx, item in pairs(tsp.getAllStacks(side).getAll()) do
        if item.name ~= nil then
            return idx
        end
    end
end

function yield_reactor() 
    rs.setOutput(rs_side, 15)
end

function resume_reactor()
    rs.setOutput(rs_side, 0)
end

function check_sth_to_replace_cell(name, side)
    while true do
        if get_valid_idx(side) ~= nil then
            return
        end
        if name == "cell" then
            print("waiting for clean cell")
        else
            print("RUNNING OUT OF FUEL!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        end
        os.sleep(8)
    end
end

function do_replace_dirty_cell(name, idx, waste_side, clean_side)
    -- print("running replacement procedure...")
    -- print(string.format("try replacing %s at %d", name, idx))
    check_sth_to_replace_cell(name, clean_side)
    tar_idx = get_empty_idx(waste_side) + 1
    -- print(string.format("%s transferring from %.0f to %.0f", name, idx, tar_idx))
    assert(tsp.transferItem(
        reactor_direction, -- src_side
        waste_side, -- tar_side
        1,    -- count
        idx,  -- src_idx
        tar_idx -- tar_idx
    ) ~= 0)
    src_idx = get_valid_idx(clean_side) + 1
    -- print(string.format("%s transferring from %.0f to %.0f", name, src_idx, idx))
    assert(tsp.transferItem(
        clean_side, -- src_side
        reactor_direction, -- tar_side
        1,  -- count
        src_idx,  -- src_idx
        idx -- tar_idx
    ) ~= 0)
    -- print("running replacement procedure success.")
end

function wait_until_need_enegry() 
    while true do 
        now = 0
        for i=1, num_batteries, 1 do 
            now = now + bf.getBatteryCharge(i)
        end
        tot = num_batteries * battery_max_sotrage
        print(string.format("enegry: %.0f / %.0f, %.3f%%", now, tot, now / tot * 100))
        if now / tot * 100 <= 98 then
            return 
        else 
            print("enegry fully charged!")
            os.sleep(60)
        end
    end
end

while true do

    wait_until_need_enegry()

    yield_reactor()

    os.sleep(0.8)

    for idx, item in pairs(tsp.getAllStacks(reactor_direction).getAll()) do
        if item.name ~= nil then
            if string.find(item.name, cell_name) ~= nil then
                if item.damage >= 95 then
                    do_replace_dirty_cell("cell", idx + 1, dirty_cell_direction, clean_cell_direction)
                end
            elseif string.find(item.name, fuel_waste_name) ~= nil then
                do_replace_dirty_cell("fuel", idx + 1, fuel_waste_direction, fuel_direction)
            end
        end
    end

    resume_reactor()

    os.sleep(1.2)
end
