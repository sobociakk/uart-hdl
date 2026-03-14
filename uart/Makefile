# ==========================================
# Verification Makefile (Vivado XSIM)
# ==========================================

# Toolchain definition
XVLOG  = xvlog
XELAB  = xelab
XSIM   = xsim
LINTER = verilator
PYTHON = python3

# Target modules
RTL_TOP ?= rtl_top
TB_NAME ?= tb_name

# Directories and filelists
RTL_DIR      = rtl
TB_DIR       = tb
BUILD_DIR    = build
RTL_FILELIST = $(RTL_DIR)/rtl.f
TB_FILELIST  = $(TB_DIR)/$(TB_NAME).f

# Tool flags
LINT_FLAGS = --lint-only -Wall -sv --top-module $(RTL_TOP)

# Source files for dependency tracking
SOURCES = $(shell find $(RTL_DIR) $(TB_DIR) -type f \( -name '*.v' -o -name '*.sv' \) 2>/dev/null) $(RTL_FILELIST) $(TB_FILELIST)

# Dependency markers
LINT_MARKER    = $(BUILD_DIR)/.lint.done
COMPILE_MARKER = $(BUILD_DIR)/.compile.done
ELAB_MARKER    = $(BUILD_DIR)/.elab.done

.PHONY: all lint compile elaborate sim wave clean setup

all: lint sim

setup:
	@mkdir -p $(BUILD_DIR)

# --- Linting ---
lint: $(LINT_MARKER)

$(LINT_MARKER): $(SOURCES) | setup
	@echo "=== 1. Linting module: $(RTL_TOP) ==="
	$(LINTER) $(LINT_FLAGS) -f $(RTL_FILELIST)
	@touch $@

# --- Compilation ---
compile: $(COMPILE_MARKER)

$(COMPILE_MARKER): $(SOURCES) | setup
	@echo "=== 2. Compiling for: $(TB_NAME) ==="
	$(XVLOG) -sv -f $(TB_FILELIST) -log $(BUILD_DIR)/xvlog.log
	@touch $@

# --- Elaboration ---
elaborate: $(ELAB_MARKER)

$(ELAB_MARKER): $(COMPILE_MARKER)
	@echo "=== 3. Elaborating: $(TB_NAME) ==="
	$(XELAB) -debug typical -top $(TB_NAME) -snapshot $(TB_NAME)_snap -log $(BUILD_DIR)/xelab.log
	@touch $@

# --- Simulation ---
sim: elaborate
	@echo "=== 4. Running Simulation ==="
	@echo "log_wave -recursive *; run all; exit" > $(BUILD_DIR)/xsim_cfg.tcl
	$(XSIM) $(TB_NAME)_snap -tclbatch $(BUILD_DIR)/xsim_cfg.tcl -log $(BUILD_DIR)/xsim_run.log | tee $(BUILD_DIR)/$(TB_NAME)_sim_stdout.log
	@echo "=== Analyzing log ==="
	@$(PYTHON) scripts/check_sim.py $(BUILD_DIR)/$(TB_NAME)_sim_stdout.log || true

# --- Waveform Viewing ---
wave:
	@echo "=== Opening Vivado XSIM GUI ==="
	$(XSIM) $(TB_NAME)_snap -gui

# --- Cleanup ---
clean:
	@echo "=== Cleaning Workspace ==="
	rm -rf $(BUILD_DIR)
	rm -rf xsim.dir .Xil
	rm -f *.jou *.log *.pb *.wdb *_snap