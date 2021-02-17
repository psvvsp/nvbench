#pragma once

#include <nvbench/flags.cuh>

#include <type_traits>

namespace nvbench::detail
{

// See the similarly named tags in nvbench::exec_tag:: for documentation.
enum class exec_flag
{
  none = 0x0,

  // Modifiers:
  timer    = 0x1, // KernelLauncher uses manual timing
  no_block = 0x2, // Disables use of `blocking_kernel`. Needed when KL syncs.

  // Measurement types:
  cold = 0x4,  // measure_hot
  hot  = 0x8,  // measure_cold
  cpu  = 0x10, // measure_cpu

  // Masks:
  modifier_mask = timer | no_block,
  measure_mask  = cold | hot | cpu
};

} // namespace nvbench::detail

NVBENCH_DECLARE_FLAGS(nvbench::detail::exec_flag)

namespace nvbench::exec_tag
{

namespace impl
{

struct tag_base
{};

template <typename ExecTag>
constexpr inline bool is_exec_tag_v = std::is_base_of_v<tag_base, ExecTag>;

/// Base class for exec_tag functionality.
/// This exists so that the `exec_flag`s can be embedded in a type with flag
/// semantics. This allows state::exec to only instantiate the measurements
/// that are actually used.
template <nvbench::detail::exec_flag Flags>
struct tag
    : std::integral_constant<nvbench::detail::exec_flag, Flags>
    , tag_base
{
  static constexpr nvbench::detail::exec_flag flags = Flags;

  template <nvbench::detail::exec_flag OFlags>
  constexpr auto operator|(tag<OFlags>) const
  {
    return tag<Flags | OFlags>{};
  }

  template <nvbench::detail::exec_flag OFlags>
  constexpr auto operator&(tag<OFlags>) const
  {
    return tag<Flags & OFlags>{};
  }

  constexpr auto operator~() const { return tag<~Flags>{}; }

  constexpr operator bool() const // NOLINT(google-explicit-constructor)
  {
    return Flags != nvbench::detail::exec_flag::none;
  }
};

using none_t          = tag<nvbench::detail::exec_flag::none>;
using timer_t         = tag<nvbench::detail::exec_flag::timer>;
using no_block_t      = tag<nvbench::detail::exec_flag::no_block>;
using hot_t           = tag<nvbench::detail::exec_flag::hot>;
using cold_t          = tag<nvbench::detail::exec_flag::cold>;
using cpu_t           = tag<nvbench::detail::exec_flag::cpu>;
using modifier_mask_t = tag<nvbench::detail::exec_flag::modifier_mask>;
using measure_mask_t  = tag<nvbench::detail::exec_flag::measure_mask>;

constexpr inline none_t none;
constexpr inline timer_t timer;
constexpr inline no_block_t no_block;
constexpr inline cold_t cold;
constexpr inline hot_t hot;
constexpr inline cpu_t cpu;
constexpr inline modifier_mask_t modifier_mask;
constexpr inline measure_mask_t measure_mask;

} // namespace impl

/// Modifier used when only a portion of the KernelLauncher needs to be timed.
/// Useful for resetting state in-between timed kernel launches.
constexpr inline auto timer = nvbench::exec_tag::impl::timer;

/// Modifier used to indicate that the KernelGenerator will perform CUDA
/// synchronizations. Without this flag such benchmarks will deadlock.
constexpr inline auto sync = nvbench::exec_tag::impl::no_block;

/// Request Cold measurements.
constexpr inline auto cold = nvbench::exec_tag::impl::cold;

/// Request Hot measurements.
constexpr inline auto hot = nvbench::exec_tag::impl::hot;

/// Request CPU-only measurements.
constexpr inline auto cpu = nvbench::exec_tag::impl::cpu;

/// Requests hot and cold CUDA measurements with no modifiers.
constexpr inline auto cuda = hot | cold;

/// The default tag; used when none specified.
constexpr inline auto default_tag = cuda;

} // namespace nvbench::exec_tag
