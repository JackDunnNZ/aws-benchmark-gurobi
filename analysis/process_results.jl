using DataFrames
using Plots

RAW_PATH = "../results/raw/"
PROCESSED_PATH = "../results/processed/"
PLOTS_PATH = "../plots/"

AWS_REGION = "us-east-1"

include("instance_data.jl")
gadfly()

function decode_files(raw_path, processed_path)

  for file in readdir(raw_path)
    filepath = joinpath(raw_path, file)
    results = readcsv(filepath)
    if results[1, 1:2] != ["inst_type" "results"]
      println("Invalid format: $file")
      continue
    end

    inst_type = results[2, 1]
    # The b64 output might have commas in the encoding, so we put them back in
    output_data_enc = join(results[2, 2:end], ",")
    output_data = ascii(base64decode(output_data_enc))

    # Delete irrelevant rows
    output_rows = split(output_data, "\n")
    nrows = length(output_rows)
    output_rows = output_rows[setdiff(1:nrows, [1; 3; 91:nrows])]

    # Process header
    header = output_rows[1]
    # Kill pipe separators
    header = replace(header, "|", " ")
    # Delete spaces in titles
    header_cols = split(header, "  ", keep=false)
    map!(row -> replace(row, " ", ""), header_cols)
    header = join(header_cols, " ")
    # Re-insert header
    output_rows[1] = header

    # Reform output
    output_data = join(output_rows, "\n")

    open(joinpath(processed_path, inst_type), "w") do f
      write(f, output_data)
    end
  end
end

function aggregate_data(processed_path)
  inst_data = get_instance_data()

  df = DataFrame()
  for filename in readdir(processed_path)
    filepath = joinpath(processed_path, filename)
    inst_df = readtable(filepath, separator=' ')

    family, size = split(filename, ".")
    inst_df[:InstFamily] = family
    inst_df[:InstSize]   = size
    inst_df[:InstName]   = filename
    df = vcat(df, inst_df)
  end
  pool!(df, [:Name, :InstFamily, :InstSize, :InstName])
  df[:InstNumCPU] = map(x -> inst_data[AWS_REGION][x].num_cpu, df[:InstName])
  df[:InstPrice]  = map(x -> inst_data[AWS_REGION][x].price,   df[:InstName])
  df[:InstRAM]    = map(x -> inst_data[AWS_REGION][x].ram,     df[:InstName])
  df[:InstECU]    = map(x -> inst_data[AWS_REGION][x].ecu,     df[:InstName])
  df
end

function make_individual_plots(df, plots_path)
  if !isdir(plots_path)
    mkdir(plots_path)
  end
  sort!(df, cols = [:InstNumCPU])
  for subdf in groupby(df, :Name)
    name = subdf[1, :Name]
    println(name)
    p = Plots.plot(subdf, :InstNumCPU, :Time,
        group=:InstFamily,
        linestyle=:solid,
        marker=:auto,
        title=name,
        xlabel="Num. CPU",
        ylabel="time (s)",
    )
    Plots.pdf(p, joinpath(plots_path, "$name.pdf"))
  end
end

function make_anns(df::DataFrame, x::Symbol, y::Symbol)
  dy = maximum(df[y]) / 20
  collect(zip(
    log2(df[x]),
    df[y] + dy - 2 * dy * (df[:InstFamily] .== "c4"),
    map(x->text(x, 6, :center, "Helvetica Bold"), df[:InstSize])
  ))
end

function make_joint_plot(df, plots_path)
  if !isdir(plots_path)
    mkdir(plots_path)
  end

  df[:TotalCost] = df[:InstPrice] .* df[:Time] / 3600
  final_df = by(df, :InstName) do subdf
    newdf = subdf[1, :]
    newdf[:Time_geomean] = geomean(subdf[:Time])
    newdf[:Time_mean] = mean(subdf[:Time])
    newdf[:TotalCost_geomean] = geomean(subdf[:TotalCost])
    newdf[:TotalCost_sum] = sum(subdf[:TotalCost])
    newdf
  end
  sort!(final_df, cols=[:InstPrice])
  p = Plots.plot(final_df, :InstPrice, :Time_geomean,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstPrice, :Time_geomean),
      title="Geomean of wallclock time across all instances",
      xlabel="Unit price (\$/hour)",
      ylabel="time (s)",
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "time_geomean.pdf"))
  p = Plots.plot(final_df, :InstPrice, :Time_mean,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstPrice, :Time_mean),
      title="Mean wallclock time across all instances",
      xlabel="Unit price (\$/hour)",
      ylabel="time (s)",
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "time_mean.pdf"))
  p = Plots.plot(final_df, :InstPrice, :TotalCost_geomean,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstPrice, :TotalCost_geomean),
      title="Geomean of total cost across all instances against unit price",
      xlabel="Unit price (\$/hour)",
      ylabel="cost (\$)",
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "cost_geomean.pdf"))
  p = Plots.plot(final_df, :InstPrice, :TotalCost_sum,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstPrice, :TotalCost_sum),
      title="Total cost to run all instances against unit price",
      xlabel="Unit price (\$/hour)",
      ylabel="cost (\$)",
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "cost_sum.pdf"))
  p = Plots.plot(final_df, :InstRAM, :TotalCost_sum,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstRAM, :TotalCost_sum),
      title="Total cost to run all instances against RAM",
      xlabel="Instance RAM (GB)",
      ylabel="cost (\$)",
      xticks=0:8,
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "cost_sum_ram.pdf"))
  p = Plots.plot(final_df, :InstRAM, :TotalCost_geomean,
      group=:InstFamily,
      linestyle=:solid,
      marker=:auto,
      ann=make_anns(final_df, :InstRAM, :TotalCost_geomean),
      title="Geomean of total cost across all instances against RAM",
      xlabel="Instance RAM (GB)",
      ylabel="cost (\$)",
      xticks=0:8,
      xscale=:log2,
  )
  Plots.pdf(p, joinpath(plots_path, "cost_geomean_ram.pdf"))
end

decode_files(RAW_PATH, PROCESSED_PATH)
df = aggregate_data(PROCESSED_PATH)
make_individual_plots(df, joinpath(PLOTS_PATH, "individual"))
make_joint_plot(df, joinpath(PLOTS_PATH, "joint"))

