#!/usr/bin/env tclsh

# =====================================================================
# Vivado Binary Search: Parameter Space Exploration & Timing Analysis
# Generic TCL for Parameterized Design Testing
# =====================================================================

# =====================================================================
# CONFIGURATION SECTION - MODIFY THESE FOR YOUR PROJECT
# =====================================================================

# Binary Search Parameters
set CLOCK_PERIOD_MAX 10.0       ;# Maximum clock period (ns) - 100 MHz
set CLOCK_PERIOD_MIN 1.0        ;# Minimum clock period (ns) - 1000 MHz
set PRECISION        0.2        ;# Precision level (ns)

# Project Configuration
set PROJECT_DIR     "./vivado_vistrutah"
set PROJECT_NAME    "vivado_vistrutah"
set TOP_MODULE      "top_module"
set CLOCK_PORT      "clk"       ;# Clock port name (e.g., clk, clock, sys_clk, clk_i)

# Results file
set results_file    "./report_output.txt"

# =====================================================================
# FPGA PARTS CONFIGURATION
# =====================================================================
# List of FPGA parts to test
# Format: {part_name "Display Label"}
set FPGA_PARTS {
    {xcku5p-ffvb676-2-e "KCU116 (xcku5p)"}
}

# Example for testing multiple FPGAs:
# set FPGA_PARTS {
#     {xcku5p-ffvb676-2-e "KCU116 (xcku5p)"}
#     {xc7a200tfbg676-2   "AC701 (xc7a200t)"}
#     {xczu9eg-ffvb1156-2-e "ZCU102 (xczu9eg)"}
# }

# =====================================================================
# GENERIC/PARAMETER CONFIGURATION - FULLY DYNAMIC
# =====================================================================
# Define parameters: list of {name label values_list}
# Can have 1, 2, 3, or more parameters
set PARAMETERS {
    {G_BLOCK_SIZE   "Block Size"   {64}}
    {G_KEY_SIZE     "Key Size"     {32 64}}
}

# Example for 3 parameters:
# set PARAMETERS {
#     {DEPTH         "Depth"        {16 32 64}}
#     {WIDTH         "Width"        {8 16 32}}
#     {NUM_STREAMS   "Num Streams"  {1 2 4}}
# }

# Generate all parameter combinations (cartesian product)
proc generate_combinations {parameters} {
    if {[llength $parameters] == 0} {
        return {{}}
    }

    set first_param [lindex $parameters 0]
    set rest_params [lrange $parameters 1 end]

    set param_name [lindex $first_param 0]
    set param_values [lindex $first_param 2]

    set rest_combinations [generate_combinations $rest_params]

    set result {}
    foreach value $param_values {
        foreach combo $rest_combinations {
            lappend result [linsert $combo 0 $value]
        }
    }
    return $result
}

# Generate combinations
set param_combinations [generate_combinations $PARAMETERS]
set num_configs [llength $param_combinations]

# Store results for all configs
array set all_results {}

# Display header
puts "=========================================================================="
puts "COMPREHENSIVE BINARY SEARCH: Parameter Space Exploration"
puts "=========================================================================="
puts "Test Configurations:"

set config_num 1
foreach combo $param_combinations {
    set display_str "  Config $config_num:"
    set config_index 0
    foreach param $PARAMETERS {
        set param_name [lindex $param 0]
        set param_label [lindex $param 1]
        set param_value [lindex $combo $config_index]
        append display_str " $param_label=$param_value"
        incr config_index
    }
    puts $display_str
    incr config_num
}
puts "=========================================================================="
puts "Binary Search Parameters:"
puts "  MAX Period: $CLOCK_PERIOD_MAX ns"
puts "  MIN Period: $CLOCK_PERIOD_MIN ns"
puts "  Precision: $PRECISION ns"
puts "=========================================================================="

# Initialize results file
set fp [open $results_file w]
puts $fp "=========================================================================="
puts $fp "COMPREHENSIVE BINARY SEARCH RESULTS"
puts $fp "Date: [clock format [clock seconds]]"
puts $fp "=========================================================================="
puts $fp ""
puts $fp "Binary Search Parameters:"
puts $fp "  MAX Period: $CLOCK_PERIOD_MAX ns (100 MHz)"
puts $fp "  MIN Period: $CLOCK_PERIOD_MIN ns (333 MHz)"
puts $fp "  Precision: $PRECISION ns"
puts $fp ""
close $fp

# =====================================================================
# Procedure: Run binary search for a single configuration
# =====================================================================
proc run_binary_search {config_name param_values config_index fpga_part} {
    global CLOCK_PERIOD_MAX CLOCK_PERIOD_MIN PRECISION
    global PROJECT_DIR PROJECT_NAME TOP_MODULE results_file
    global all_results PARAMETERS CLOCK_PORT

    # Build display string
    set display_str "Testing: $config_name ("
    set param_idx 0
    foreach param $PARAMETERS {
        set param_name [lindex $param 0]
        set param_label [lindex $param 1]
        set param_value [lindex $param_values $param_idx]
        if {$param_idx > 0} {
            append display_str ", "
        }
        append display_str "$param_label=$param_value"
        incr param_idx
    }
    append display_str ")"

    puts "\n=========================================================================="
    puts $display_str
    puts "=========================================================================="

    set clock_period_max $CLOCK_PERIOD_MAX
    set clock_period_min $CLOCK_PERIOD_MIN
    set precision $PRECISION
    set iteration 0
    set min_passing_period ""
    set max_failing_period ""

    # Open project (only if not already open)
    if {[catch {current_project} err]} {
        # No project open, open it
        open_project "$PROJECT_DIR/$PROJECT_NAME.xpr"
    } else {
        # Project already open
        puts "Project already open, skipping open_project"
    }

    # Set FPGA part
    set_property "part" $fpga_part [current_project]

    # Binary search loop
    while {[expr {$clock_period_max - $clock_period_min}] > $precision} {
        incr iteration
        set clock_period [expr {($clock_period_max + $clock_period_min) / 2.0}]
        set clock_period [format "%.1f" $clock_period]

        puts "  Iteration $iteration: Testing Period=$clock_period ns"

        # Log to monitor file
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "    \[Iter $iteration\] Testing Period=$clock_period ns"
        flush $fp_monitor
        close $fp_monitor

        # Create new run for this iteration
        set run_name "impl_${config_index}_iter_${iteration}"

        # Delete existing run if it exists
        if {[catch {get_runs $run_name} err]} {
            # Run doesn't exist, that's fine
        } else {
            delete_runs -quiet $run_name
        }

        # Get the synthesis run
        set synth_run [get_runs -filter {IS_SYNTHESIS}]
        if {[llength $synth_run] == 0} {
            puts "ERROR: No synthesis run found!"
            continue
        }
        set synth_run [lindex $synth_run 0]

        # Create implementation run with correct flow
        create_run -name $run_name -parent_run $synth_run -flow "Vivado Implementation 2023"


        # Set generics for synthesis using generic parameter names
        set generics_string ""
        set param_idx 0
        foreach param $PARAMETERS {
            set param_name [lindex $param 0]
            set param_value [lindex $param_values $param_idx]
            if {$param_idx > 0} {
                append generics_string " "
            }
            append generics_string "$param_name=$param_value"
            incr param_idx
        }
        set_property GENERIC "$generics_string" [get_filesets sources_1]

        # Remove ALL previous timing constraint files from constrs_1
        if {$iteration > 1} {
            set existing_constraints [get_files -of [get_filesets constrs_1] -filter {NAME =~ "*timing_constraints*"}]
            if {[llength $existing_constraints] > 0} {
                catch {remove_files -fileset constrs_1 $existing_constraints}
                set fp_monitor [open "./monitor.txt" a]
                puts $fp_monitor "      \[Removed previous constraint files\]"
                flush $fp_monitor
                close $fp_monitor
            }
        }

        # Create constraint file with current period BEFORE synthesis
        # Use project-relative path instead of /tmp/ to ensure Vivado can access it
        set constraint_file "$PROJECT_DIR/timing_constraints_${config_index}_${iteration}.xdc"
        set fp [open $constraint_file w]
        puts $fp "create_clock -period $clock_period \[get_ports $CLOCK_PORT\]"
        close $fp

        # Add constraint to the constraint fileset
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Adding constraint: $constraint_file (Period=$clock_period ns)\]"
        flush $fp_monitor
        close $fp_monitor

        if {[catch {add_files -fileset constrs_1 $constraint_file} err]} {
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[WARNING: Failed to add constraint: $err\]"
            flush $fp_monitor
            close $fp_monitor
        }

        # Set properties for implementation run
        set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs $run_name]
        set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs $run_name]

        # Re-run synthesis with new generics
        puts "    Running synthesis..."

        # Log to monitor file
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Running synthesis\]"
        flush $fp_monitor
        close $fp_monitor

        # Reset synthesis run before re-running
        # First, clear any incremental checkpoint that might be causing issues
        catch {set_property INCREMENTAL_CHECKPOINT {} [get_runs $synth_run]}

        if {[catch {reset_run $synth_run} err]} {
            puts "    Warning: Could not reset synthesis run: $err"
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[Warning: reset_run failed: $err\]"
            flush $fp_monitor
            close $fp_monitor
        }

        if {[catch {launch_runs -jobs 4 $synth_run} err]} {
            puts "    Synthesis error: $err"
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[Synthesis ERROR: $err\]"
            flush $fp_monitor
            close $fp_monitor
            set clock_period_max [expr {$clock_period}]
            continue
        }
        puts "    Waiting for synthesis to complete..."
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Waiting for synthesis\]"
        flush $fp_monitor
        close $fp_monitor
        wait_on_run $synth_run
        puts "    Synthesis completed"
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Synthesis completed\]"
        flush $fp_monitor
        close $fp_monitor

        # Run implementation
        puts "    Running implementation..."
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Running implementation\]"
        flush $fp_monitor
        close $fp_monitor

        if {[catch {launch_runs -jobs 4 $run_name} err]} {
            puts "    Implementation launch error: $err"
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[Implementation ERROR: $err\]"
            flush $fp_monitor
            close $fp_monitor
            set clock_period_max [expr {$clock_period}]
            continue
        }
        puts "    Waiting for implementation to complete..."
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Waiting for implementation\]"
        flush $fp_monitor
        close $fp_monitor
        wait_on_run $run_name
        puts "    Implementation completed"
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Implementation completed\]"
        flush $fp_monitor
        close $fp_monitor

        # Open the implementation design and check timing
        puts "    Opening run and checking timing..."
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[Checking timing analysis\]"
        flush $fp_monitor
        close $fp_monitor
        open_run $run_name

        # Run timing analysis with the constraints that were applied during synthesis
        # First, verify what constraints are active
        set active_constraints [get_clocks]
        set fp_monitor [open "./monitor.txt" a]
        puts $fp_monitor "      \[DEBUG\] Active clocks after implementation: $active_constraints"
        foreach clk $active_constraints {
            set clk_period [get_property PERIOD $clk]
            puts $fp_monitor "      \[DEBUG\]   Clock: $clk, Period: $clk_period ns"
        }
        flush $fp_monitor
        close $fp_monitor

        # Use project-relative path for timing report instead of /tmp/
        set timing_report_file "$PROJECT_DIR/timing_${run_name}.rpt"
        report_timing -file "$timing_report_file"

        # Parse timing report for slack
        set timing_report [open "$timing_report_file" r]
        set slack_value ""
        set period_in_report ""
        set first_lines ""
        set line_count 0
        set slack_line ""
        while {[gets $timing_report line] >= 0} {
            incr line_count
            # Capture first 10 lines for debugging
            if {$line_count <= 10} {
                append first_lines "$line\n"
            }
            # Look for the period in the report
            if {[string match "*period=*" $line]} {
                if {[regexp {period=([0-9.]+)} $line match period_in_report]} {
                    set fp_monitor [open "./monitor.txt" a]
                    puts $fp_monitor "      \[DEBUG\] Period in report: $period_in_report ns (expected: $clock_period ns)"
                    flush $fp_monitor
                    close $fp_monitor
                }
            }
            # Look for line starting with "slack" (case-insensitive) - store it but keep looking for the last one
            if {[string match -nocase "slack*" [string trim $line]]} {
                set slack_line $line
            }
        }
        close $timing_report

        # Extract slack value from the slack line (which should be the last one found)
        if {$slack_line ne ""} {
            # Look for signed number at the END of the slack line
            # Pattern: optional whitespace, optional sign, digits, optional decimal and more digits, optional "ns", optional whitespace at end
            if {[regexp {([-+]?[0-9]+(?:\.[0-9]+)?)\s*(?:ns)?\s*$} $slack_line match slack_value]} {
                # Successfully extracted slack value from end of line
            } else {
                set slack_value ""
            }

            # Debug output
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[DEBUG\] Full slack line: '$slack_line'"
            puts $fp_monitor "      \[DEBUG\] Extracted slack: '$slack_value'"
            flush $fp_monitor
            close $fp_monitor
        }

        # Debug: Log if period mismatch
        if {$period_in_report ne "" && $period_in_report ne $clock_period} {
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      \[ERROR\] PERIOD MISMATCH! Report has $period_in_report ns, but we set $clock_period ns"
            puts $fp_monitor "      First lines of report:"
            puts $fp_monitor $first_lines
            flush $fp_monitor
            close $fp_monitor
        }

        # Check if design passed
        set design_passed 0
        if {$slack_value ne "" && $slack_value >= 0} {
            set design_passed 1
            puts "    Result: PASS (Slack=$slack_value ns) - Try TIGHTER period"
            set min_passing_period $clock_period
            # PASS: Try a tighter (smaller) period next - move the max DOWN
            set clock_period_max [expr {$clock_period}]

            # Log to monitor file
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      Result: PASS (Slack=$slack_value ns) - Tightening search"
            flush $fp_monitor
            close $fp_monitor
        } else {
            puts "    Result: FAIL (Slack=$slack_value ns) - Need LOOSER period"
            set max_failing_period $clock_period
            # FAIL: Need a looser (larger) period next - move the min UP
            set clock_period_min [expr {$clock_period}]

            # Log to monitor file
            set fp_monitor [open "./monitor.txt" a]
            puts $fp_monitor "      Result: FAIL (Slack=$slack_value ns) - Loosening search"
            flush $fp_monitor
            close $fp_monitor
        }

    }

    # Note: Don't close project - keep it open for next iteration

    puts "\n$config_name Results:"
    puts "  Minimum Passing Period: $min_passing_period ns"
    if {$min_passing_period ne ""} {
        set freq [format "%.2f" [expr {1000.0 / $min_passing_period}]]
        puts "  Maximum Frequency: $freq MHz"
    }
    puts "  Iterations: $iteration"

    # Store results
    set config_key [string map {" " "_" ":" "" "/" "_"} $config_name]
    set all_results($config_key,period) $min_passing_period
    set all_results($config_key,iteration) $iteration
    set all_results($config_key,name) $config_name

    puts "  Capturing resource utilization..."
    set fp_monitor [open "./monitor.txt" a]
    puts $fp_monitor "      \[Capturing resources\]"
    flush $fp_monitor
    close $fp_monitor

    # Get resource utilization
    capture_resources $config_name $param_values

    set fp_monitor [open "./monitor.txt" a]
    puts $fp_monitor "      \[Resources captured\]"
    flush $fp_monitor
    close $fp_monitor
}

# =====================================================================
# Procedure: Capture resource utilization
# =====================================================================
proc capture_resources {config_name param_values} {
    global results_file all_results PARAMETERS PROJECT_DIR PROJECT_NAME

    puts "  Capturing resources for $config_name..."

    # Find the latest implementation utilization report file
    set util_file ""
    set runs [glob -nocomplain "$PROJECT_DIR/$PROJECT_NAME.runs/impl_*/top_module_utilization_placed.rpt"]
    if {[llength $runs] > 0} {
        # Get the latest file by modification time
        set latest_file ""
        set latest_time 0
        foreach f $runs {
            set mtime [file mtime $f]
            if {$mtime > $latest_time} {
                set latest_time $mtime
                set latest_file $f
            }
        }
        set util_file $latest_file
    }

    # Parse resources
    set lut_used "0"
    set lutram_used "0"
    set ff_used "0"
    set bram_used "0"
    set dsp_used "0"
    set total_power "0.000"

    if {$util_file ne ""} {
        # Read the utilization report file
        if {[catch {set fp [open $util_file r]}]} {
            puts "    Warning: Could not open utilization report: $util_file"
        } else {
            set util_content [read $fp]
            close $fp

            # Parse resources - looking for the table format: "| CLB LUTs* | <number>"
            # Look for CLB LUTs - pattern: "| CLB LUTs*  | <number>"
            if {[regexp {CLB LUTs\*?\s*\|\s+([0-9,]+)} $util_content match val]} {
                set lut_used [string map {, ""} $val]
            }
            # Look for LUT as Memory - pattern: "| LUT as Memory | <number>"
            if {[regexp {LUT as Memory\s*\|\s+([0-9,]+)} $util_content match val]} {
                set lutram_used [string map {, ""} $val]
            }
            # Look for CLB Registers (Flip Flops) - pattern: "| CLB Registers | <number>"
            if {[regexp {CLB Registers\s*\|\s+([0-9,]+)} $util_content match val]} {
                set ff_used [string map {, ""} $val]
            }
            # Look for Block RAM Tile - pattern: "| Block RAM Tile | <number>"
            if {[regexp {Block RAM Tile\s*\|\s+([0-9,]+)} $util_content match val]} {
                set bram_used [string map {, ""} $val]
            }
            # Look for DSP48 Slices - pattern: "| DSP48 Slices | <number>"
            if {[regexp {DSP48 Slices\s*\|\s+([0-9,]+)} $util_content match val]} {
                set dsp_used [string map {, ""} $val]
            }
        }
    }

    # Try to get power report from the latest implementation run
    if {[catch {set power_report [report_power -return_string]} err]} {
        # If report_power fails, try to read from power report file
        set power_files [glob -nocomplain "$PROJECT_DIR/$PROJECT_NAME.runs/impl_*/top_module_power.rpt"]
        if {[llength $power_files] > 0} {
            # Get the latest power report file by modification time
            set power_file ""
            set latest_ptime 0
            foreach pf $power_files {
                set ptime [file mtime $pf]
                if {$ptime > $latest_ptime} {
                    set latest_ptime $ptime
                    set power_file $pf
                }
            }
            if {[catch {set fp [open $power_file r]}]} {
                set power_report ""
            } else {
                set power_report [read $fp]
                close $fp
            }
        } else {
            set power_report ""
        }
    }

    # Parse power
    if {$power_report ne ""} {
        if {[regexp {Total On-Chip Power\s*\([^)]*\)\s*\|\s*([0-9.]+)} $power_report match val]} {
            set total_power $val
        }
    }

    # Store in results array
    set config_key [string map {" " "_" ":" "" "/" "_"} $config_name]
    set all_results($config_key,lut) $lut_used
    set all_results($config_key,lutram) $lutram_used
    set all_results($config_key,ff) $ff_used
    set all_results($config_key,bram) $bram_used
    set all_results($config_key,dsp) $dsp_used
    set all_results($config_key,power) $total_power

    puts "    LUT: $lut_used, LUTRAM: $lutram_used, FF: $ff_used"
    puts "    BRAM: $bram_used, DSP: $dsp_used, Power: ${total_power}W"
}

# =====================================================================
# Main execution loop
# =====================================================================
puts "\nStarting comprehensive binary search..."
set total_fpga_configs [expr {[llength $param_combinations] * [llength $FPGA_PARTS]}]
puts "Total configurations to test: $total_fpga_configs"
puts "  - Parameter combinations: [llength $param_combinations]"
puts "  - FPGA parts: [llength $FPGA_PARTS]"
puts "=========================================================================="

# Create monitoring file
set monitor_file "./monitor.txt"
set start_time [clock seconds]
set fp_monitor [open $monitor_file w]
puts $fp_monitor "MONITORING: Binary Search Execution"
puts $fp_monitor "Start time: [clock format $start_time]"
puts $fp_monitor "Total configs: $total_fpga_configs"
puts $fp_monitor "=========================================================================="
close $fp_monitor

set global_config_index 1
foreach fpga_info $FPGA_PARTS {
    set fpga_part [lindex $fpga_info 0]
    set fpga_label [lindex $fpga_info 1]

    puts "\n=========================================================================="
    puts "FPGA: $fpga_label ($fpga_part)"
    puts "=========================================================================="

    for {set i 0} {$i < [llength $param_combinations]} {incr i} {
        set param_values [lindex $param_combinations $i]
        set config_name "Config $global_config_index: $fpga_label"

        # Build config name with parameters
        append config_name " - "
        set param_idx 0
        foreach param $PARAMETERS {
            set param_value [lindex $param_values $param_idx]
            if {$param_idx > 0} {
                append config_name "/"
            }
            append config_name $param_value
            incr param_idx
        }

        # Update monitoring file
        set fp_monitor [open $monitor_file a]
        set current_time [clock seconds]
        set elapsed_time [expr {$current_time - $start_time}]
        set elapsed_hours [expr {$elapsed_time / 3600}]
        set elapsed_mins [expr {($elapsed_time % 3600) / 60}]
        set elapsed_secs [expr {$elapsed_time % 60}]
        puts $fp_monitor "\n\[PROGRESS\] Config $global_config_index/$total_fpga_configs: $config_name"
        puts $fp_monitor "  FPGA: $fpga_label"
        puts $fp_monitor "  Started at: [clock format $current_time]"
        puts $fp_monitor "  Elapsed time: ${elapsed_hours}h ${elapsed_mins}m ${elapsed_secs}s"
        flush $fp_monitor
        close $fp_monitor

        puts "\n=========================================================================="
        puts "PROGRESS: Config $global_config_index / $total_fpga_configs"
        puts "=========================================================================="

        run_binary_search $config_name $param_values $global_config_index $fpga_part

        # Update monitoring with completion
        set fp_monitor [open $monitor_file a]
        set current_time [clock seconds]
        set elapsed_time [expr {$current_time - $start_time}]
        set elapsed_hours [expr {$elapsed_time / 3600}]
        set elapsed_mins [expr {($elapsed_time % 3600) / 60}]
        set elapsed_secs [expr {$elapsed_time % 60}]
        puts $fp_monitor "  Completed at: [clock format $current_time]"
        puts $fp_monitor "  Total elapsed: ${elapsed_hours}h ${elapsed_mins}m ${elapsed_secs}s"
        flush $fp_monitor
        close $fp_monitor

        incr global_config_index
    }
}

# =====================================================================
# Generate consolidated results table
# =====================================================================
puts "\n=========================================================================="
puts "WRITING CONSOLIDATED RESULTS TABLE"
puts "=========================================================================="

set fp [open $results_file a]

puts $fp "\n=========================================================================="
puts $fp "CONSOLIDATED RESULTS TABLE"
puts $fp "=========================================================================="
puts $fp ""
puts $fp [format "%-18s | %-11s | %-11s | %-10s | %-7s | %-7s | %-7s | %-7s | %-7s | %-8s" \
    "Configuration" "Period (ns)" "Freq (MHz)" "Iters" "LUT" "LUTRAM" "FF" "BRAM" "DSP" "Power (W)"]
puts $fp [string repeat "─" 120]

# Iterate through all results arrays to build the results table
foreach key [array names all_results "*,name"] {
    set config_key [string range $key 0 end-5]
    set config_name $all_results($key)

    set period $all_results($config_key,period)
    set iters $all_results($config_key,iteration)
    set lut $all_results($config_key,lut)
    set lutram $all_results($config_key,lutram)
    set ff $all_results($config_key,ff)
    set bram $all_results($config_key,bram)
    set dsp $all_results($config_key,dsp)
    set power $all_results($config_key,power)

    if {$period ne ""} {
        set freq [format "%.2f" [expr {1000.0 / $period}]]
    } else {
        set freq "N/A"
    }

    puts $fp [format "%-18s | %11s | %11s | %10s | %7s | %7s | %7s | %7s | %7s | %8s" \
        $config_name $period $freq $iters $lut $lutram $ff $bram $dsp $power]
}

puts $fp ""
puts $fp "=========================================================================="
puts $fp "END OF RESULTS"
puts $fp "=========================================================================="

close $fp

puts "Results written to: $results_file"
puts "=========================================================================="
puts "Comprehensive binary search complete!"
puts "=========================================================================="
