component = require("component")
sides = require("sides")

reactor_direction = sides.west
dirty_cell_direction = sides.east
clean_cell_direction = sides.north
fuel_waste_direction = sides.up
fuel_direction = sides.down
rs_side = sides.west
cell_name = "60k_NaK"
fuel_waste_name = "______"
log_duration = 300
check_duration = 1
eu_t_full = 43600

tsp = component.transposer
rs = component.redstone

running_time = 0
waiting_time = 0

lst_duration = 0

function get_valid_idx(side) 
    while true do
        for idx, item in pairs(tsp.getAllStacks(side)) do
            if item == nil then
                return idx
            end
        end
        print("waiting for empty space in dirty cell chest")
        os.sleep(8)
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
        if tsp.getStackInSlot(clean_cell_direction, 1) ~= nil then
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
    print("running replacement procedure...")
    print(string.format("try replacing %s at %d", name, idx))
    check_sth_to_replace_cell(name, clean_side)
    tsp.transferItem(
        reactor_direction, -- src_side
        waste_side, -- tar_side
        1,    -- count
        idx,  -- src_idx
        get_valid_idx(waste_side) -- tar_idx
    )
    tsp.transferItem(
        clean_side, -- src_side
        reactor_direction, -- tar_side
        1,  -- count
        1,  -- src_idx
        idx -- tar_idx
    )
    print("running replacement procedure success.")
end

function print_log() 
    print("----------LOG----------")
    print(string.format(
            "efficiency: %.3f%%, generating $.0f EU/t", 
            waiting_time / running_time * 100,
            waiting_time / running_time * eu_t_full
        )
    )
    print("----------LOG----------")
end

begin = os.time()

while true do

    os.sleep(check_duration)

    tic = os.time()

    yield_reactor()

    for idx, item in pairs(tsp.getAllStacks(reactor_direction)) do
        if item ~= nil then
            if string.find(item.name, cell_name) ~= nil then
                if item.damage >= 98 then
                    do_replace_dirty_cell("cell", idx, dirty_cell_direction, clean_cell_direction)
                end
            else if string.find(item.name, fuel_waste_name) ~= nil then
                do_replace_dirty_cell("fuel", idx, fuel_waste_direction, fuel_direction)
            end
        end
    end

    resume_reactor()

    waiting_time += os.time() - tic

    running_time = os.time() - begin

    if running_time >= log_duration then
        print_log()
        waiting_time = 0
        begin = os.time()
    end
end
