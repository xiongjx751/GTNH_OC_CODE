component = require("component")
sides = require("sides")

bf = component.gt_machine

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

while true do

    print(string.format("%sEU / %sEU, %.3f%% charged", 
        fmtEU(bf.getEUStored()), 
        fmtEU(bf.getEUMaxStored()), 
        bf.getEUStored() / bf.getEUMaxStored() * 100
    ))

    os.sleep(8)
end
