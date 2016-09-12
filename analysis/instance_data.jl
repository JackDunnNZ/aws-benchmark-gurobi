immutable InstanceInfo
  name
  num_cpu::Int
  ecu
  ram
  price::Float64
end


function get_instance_data()
  const INSTANCE_DATA_FILE = "instance-data.json"
  if !isfile(INSTANCE_DATA_FILE)
    run(`python get_instance_data.py`)
  end
  data = JSON.parsefile(INSTANCE_DATA_FILE)

  instance_data = Dict{ASCIIString, Dict{ASCIIString, InstanceInfo}}()

  regions = data["config"]["regions"]
  for region in regions
    cur_instances = Dict{ASCIIString, InstanceInfo}()
    region_name = region["region"]
    instance_types = region["instanceTypes"]
    for inst_family in instance_types
      insts = inst_family["sizes"]
      for inst in insts
        inst_num_cpu = parse(Int, inst["vCPU"])
        inst_name    = inst["size"]
        inst_ram     = float(inst["memoryGiB"])
        inst_ecu     = inst["ECU"]
        inst_price   = float(inst["valueColumns"][1]["prices"]["USD"])
        cur_instances[inst_name] = InstanceInfo(inst_name, inst_num_cpu,
                                                inst_ecu, inst_ram, inst_price)
      end
    end
    instance_data[region_name] = cur_instances
  end

  instance_data
end
