import '../models/overclock_model.dart';

/// 159개 전체 오버클럭 정적 데이터
/// 출처: https://deeprockgalactic.wiki.gg/wiki/Weapon_Overclocks
const List<DwarfCharacter> allDwarves = [
  // ════════════════════════════════════════════════════════════════
  // DRILLER (39 OCs)
  // ════════════════════════════════════════════════════════════════
  DwarfCharacter(
    dwarfClass: DwarfClass.driller,
    name: 'Driller',
    imagePath: 'assets/images/character/300px-Driller.webp',
    weapons: [
      // ── CRSPR Flamethrower (7 OCs) ──
      Weapon(
        id: 'crspr_flamethrower',
        name: 'CRSPR Flamethrower',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'driller_crspr_lighter_tanks', name: 'Lighter Tanks', tier: OverclockTier.clean, effect: '+75 Max Fuel', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'driller_crspr_sticky_additive', name: 'Sticky Additive', tier: OverclockTier.clean, effect: '+1 Damage, +1s Sticky Flame Duration', icon: 'icon_upgrade_duration'),
          Overclock(id: 'driller_crspr_compact_feed_valves', name: 'Compact Feed Valves', tier: OverclockTier.balanced, effect: '+25 Max Fuel, -2 Damage', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'driller_crspr_fuel_stream_diffuser', name: 'Fuel Stream Diffuser', tier: OverclockTier.balanced, effect: '+5m Flame Reach, -20 Max Fuel', icon: 'icon_upgrade_distance'),
          Overclock(id: 'driller_crspr_face_melter', name: 'Face Melter', tier: OverclockTier.unstable, effect: '+2 Damage, +4 Rate of Fire, -75 Max Fuel, -2m Flame Reach', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_crspr_sticky_fuel', name: 'Sticky Fuel', tier: OverclockTier.unstable, effect: '+6s Sticky Flame Duration, +1 Sticky Flame Damage, -25 Max Fuel, -75% Flow Rate', icon: 'icon_upgrade_duration'),
          Overclock(id: 'driller_crspr_compact_feed_mechanism', name: 'Compact Feed Mechanism', tier: OverclockTier.unstable, effect: 'Kills set enemies on fire in 3m radius, -2 Damage, -25 Max Fuel', icon: 'icon_overclock_special_magazine'),
        ],
      ),
      // ── Cryo Cannon (7 OCs) ──
      Weapon(
        id: 'cryo_cannon',
        name: 'Cryo Cannon',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'driller_cryo_improved_thermal_efficiency', name: 'Improved Thermal Efficiency', tier: OverclockTier.clean, effect: '+25 Tank Capacity, -0.2 Chargeup Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'driller_cryo_tuned_cooler', name: 'Tuned Cooler', tier: OverclockTier.clean, effect: '+0.8 Freezing Power, +25% Flow Rate', icon: 'icon_upgrade_cold'),
          Overclock(id: 'driller_cryo_flow_rate_expansion', name: 'Flow Rate Expansion', tier: OverclockTier.balanced, effect: '+170% Pressure Gain Rate, +25% Flow Rate, -25 Tank Capacity', icon: 'icon_upgrade_duration'),
          Overclock(id: 'driller_cryo_ice_spear', name: 'Ice Spear', tier: OverclockTier.balanced, effect: 'Press reload to fire ice projectile (100 dmg), -50 Tank Capacity', icon: 'icon_upgrade_projectile_speed'),
          Overclock(id: 'driller_cryo_ice_storm', name: 'Ice Storm', tier: OverclockTier.unstable, effect: '+2 Damage, +100% Damage vs Frozen, -3 Freezing Power, -75 Tank Capacity', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_cryo_snowball', name: 'Snowball', tier: OverclockTier.unstable, effect: 'Press reload to shoot snowball (AoE freeze), -100 Tank Capacity, +1 Chargeup Time', icon: 'icon_upgrade_area'),
          Overclock(id: 'driller_cryo_cold_radiance', name: 'Cold Radiance', tier: OverclockTier.unstable, effect: 'Continuous AoE freeze around player while firing, -75 Tank Capacity, -50% Flow Rate', icon: 'icon_upgrade_cold'),
        ],
      ),
      // ── Corrosive Sludge Pump (7 OCs) ──
      Weapon(
        id: 'corrosive_sludge_pump',
        name: 'Corrosive Sludge Pump',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'driller_sludge_hydrogen_ion_additive', name: 'Hydrogen Ion Additive', tier: OverclockTier.clean, effect: '+1 Damage, +30% Corrosive DoT Duration', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_sludge_ag_mixture', name: 'AG Mixture', tier: OverclockTier.clean, effect: '+2 Charged Shot Area Damage, -0.4s Charge Time', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'driller_sludge_volatile_impact_mixture', name: 'Volatile Impact Mixture', tier: OverclockTier.balanced, effect: '+4 Damage, +25 Charged Shot Area Damage, Cannot leave puddles', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_sludge_disperser_compound', name: 'Disperser Compound', tier: OverclockTier.balanced, effect: '+6 Normal Shot Area Damage, +50% Normal Shot Velocity, -1 Ammo per shot', icon: 'icon_upgrade_area'),
          Overclock(id: 'driller_sludge_goo_bomber_special', name: 'Goo Bomber Special', tier: OverclockTier.unstable, effect: 'Charged shot fragments into multiple projectiles, -50% Charged Shot Cost, -2 Normal Damage', icon: 'icon_overclock_special_magazine'),
          Overclock(id: 'driller_sludge_sludge_blast', name: 'Sludge Blast', tier: OverclockTier.unstable, effect: 'Normal shot fires 5 projectiles (shotgun), Damage converted to Kinetic, No puddles on normal shot', icon: 'icon_upgrade_shotgun_blast'),
          Overclock(id: 'driller_sludge_anthem_of_corrosion', name: 'Anthem of Corrosion', tier: OverclockTier.unstable, effect: '+100% Puddle Duration, Puddles slow 75%, -2 Normal Damage, -50% Normal Shot Velocity', icon: 'icon_upgrade_acid'),
        ],
      ),
      // ── Subata 120 (6 OCs) ──
      Weapon(
        id: 'subata_120',
        name: 'Subata 120',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'driller_subata_chain_hit', name: 'Chain Hit', tier: OverclockTier.clean, effect: '75% chance to ricochet to nearby enemy', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'driller_subata_homebrew_powder', name: 'Homebrew Powder', tier: OverclockTier.clean, effect: 'Damage randomly between x0.8 and x1.4', icon: 'icon_overclock_change_of_higher_damage'),
          Overclock(id: 'driller_subata_oversized_magazine', name: 'Oversized Magazine', tier: OverclockTier.balanced, effect: '+10 Magazine Size, -1 Rate of Fire', icon: 'icon_upgrade_clip_size'),
          Overclock(id: 'driller_subata_automatic_fire', name: 'Automatic Fire', tier: OverclockTier.balanced, effect: 'Full-auto mode, +2 Rate of Fire, +50% Recoil, +100% Spread per Shot', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'driller_subata_explosive_reload', name: 'Explosive Reload', tier: OverclockTier.unstable, effect: 'Last 3 bullets in magazine deal AoE damage, -50% Max Ammo, -50% Magazine Size', icon: 'icon_upgrade_area'),
          Overclock(id: 'driller_subata_tranquilizer_rounds', name: 'Tranquilizer Rounds', tier: OverclockTier.unstable, effect: '50% chance to Stun for 3s, -4 Magazine Size, -4 Rate of Fire', icon: 'icon_upgrade_stun'),
        ],
      ),
      // ── Experimental Plasma Charger (6 OCs) ──
      Weapon(
        id: 'experimental_plasma_charger',
        name: 'Experimental Plasma Charger',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'driller_epc_energy_rerouting', name: 'Energy Rerouting', tier: OverclockTier.clean, effect: '+16 Charged Shot Damage, -32 Battery Capacity', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_epc_magnetic_cooling_unit', name: 'Magnetic Cooling Unit', tier: OverclockTier.clean, effect: '+25% Cooling Rate, +50% Charge Speed', icon: 'icon_upgrade_speed'),
          Overclock(id: 'driller_epc_heat_pipe', name: 'Heat Pipe', tier: OverclockTier.balanced, effect: '-2 Charged Shot Ammo Use, +50% Charge Speed, +50% Heat Generation on Normal Shot', icon: 'icon_upgrade_fuel'),
          Overclock(id: 'driller_epc_heavy_hitter', name: 'Heavy Hitter', tier: OverclockTier.balanced, effect: '+60% Normal Damage, -32 Battery, -2 Rate of Fire', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_epc_overcharger', name: 'Overcharger', tier: OverclockTier.unstable, effect: '+50% Charged Damage, +50% Charged AoE, +50% Charged Shot Ammo Use, No Charged Shot Terrain Damage', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'driller_epc_persistent_plasma', name: 'Persistent Plasma', tier: OverclockTier.unstable, effect: 'Charged Shot leaves plasma field (6s), -20 Charged Shot Damage, -20 Battery', icon: 'icon_upgrade_duration'),
        ],
      ),
      // ── Colette Wave Cooker (6 OCs) ──
      Weapon(
        id: 'colette_wave_cooker',
        name: 'Colette Wave Cooker',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'driller_colette_liquid_cooling_system', name: 'Liquid Cooling System', tier: OverclockTier.clean, effect: '+25% Cooling Rate, -50% Overheat Duration', icon: 'icon_upgrade_speed'),
          Overclock(id: 'driller_colette_super_focus_lens', name: 'Super Focus Lens', tier: OverclockTier.clean, effect: '+4 Damage, -0.5m Beam Width', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'driller_colette_diffusion_ray', name: 'Diffusion Ray', tier: OverclockTier.balanced, effect: '+1.5m Beam Width, -2 Damage, Reduced Range', icon: 'icon_upgrade_area'),
          Overclock(id: 'driller_colette_mega_power_supply', name: 'Mega Power Supply', tier: OverclockTier.balanced, effect: '+80 Ammo, -1 Damage', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'driller_colette_blistering_necrosis', name: 'Blistering Necrosis', tier: OverclockTier.unstable, effect: 'Damage leaves permanent damage bonus on enemies, -50 Ammo, -1 Damage', icon: 'icon_upgrade_acid'),
          Overclock(id: 'driller_colette_gamma_contamination', name: 'Gamma Contamination', tier: OverclockTier.unstable, effect: 'Killed enemies leave radiation field, -2 Damage, +50% Heat Generation', icon: 'icon_upgrade_radioactive'),
        ],
      ),
    ],
  ),

  // ════════════════════════════════════════════════════════════════
  // ENGINEER (38 OCs)
  // ════════════════════════════════════════════════════════════════
  DwarfCharacter(
    dwarfClass: DwarfClass.engineer,
    name: 'Engineer',
    imagePath: 'assets/images/character/300px-Engineer.webp',
    weapons: [
      // ── "Warthog" Auto 210 (6 OCs) ──
      Weapon(
        id: 'warthog_auto_210',
        name: '"Warthog" Auto 210',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'engineer_warthog_stunner', name: 'Stunner', tier: OverclockTier.clean, effect: '+30% Stun Chance on all pellets', icon: 'icon_upgrade_stun'),
          Overclock(id: 'engineer_warthog_light_weight_magazines', name: 'Light-Weight Magazines', tier: OverclockTier.clean, effect: '+2 Magazine Size, +0.4 Reload Speed', icon: 'icon_upgrade_clip_size'),
          Overclock(id: 'engineer_warthog_magnetic_pellet_alignment', name: 'Magnetic Pellet Alignment', tier: OverclockTier.balanced, effect: '-50% Base Spread, +30% Weakpoint Bonus, -20% Rate of Fire', icon: 'icon_upgrade_aim'),
          Overclock(id: 'engineer_warthog_cycle_overload', name: 'Cycle Overload', tier: OverclockTier.unstable, effect: '+1 Damage, +2 Rate of Fire, +0.5 Reload Time, +50% Base Spread', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'engineer_warthog_mini_shells', name: 'Mini Shells', tier: OverclockTier.unstable, effect: '+90 Max Ammo, +6 Magazine Size, -2 Damage, No Stun, No Stagger', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'engineer_warthog_miner_adjustments', name: 'Miner Adjustments', tier: OverclockTier.clean, effect: '+1 Damage, -0.2 Reload Time', icon: 'icon_upgrade_damage_general'),
        ],
      ),
      // ── "Stubby" Voltaic SMG (7 OCs) ──
      Weapon(
        id: 'stubby_voltaic_smg',
        name: '"Stubby" Voltaic SMG',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'engineer_stubby_super_slim_rounds', name: 'Super-Slim Rounds', tier: OverclockTier.clean, effect: '+5 Magazine Size, -20% Base Spread', icon: 'icon_upgrade_clip_size'),
          Overclock(id: 'engineer_stubby_well_oiled_machine', name: 'Well Oiled Machine', tier: OverclockTier.clean, effect: '+2 Rate of Fire, -0.2 Reload Time', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'engineer_stubby_turret_em_discharge', name: 'EM Refire Booster', tier: OverclockTier.balanced, effect: '+2 Electric Damage, +2 Rate of Fire, -5 Magazine Size', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'engineer_stubby_light_weight_rounds', name: 'Light-Weight Rounds', tier: OverclockTier.balanced, effect: '+180 Max Ammo, -1 Damage, -2 Rate of Fire', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'engineer_stubby_turret_arc', name: 'Turret Arc', tier: OverclockTier.unstable, effect: 'Electrocuted enemies arc to turrets, -5 Magazine Size, -2 Rate of Fire', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'engineer_stubby_turret_em_discharge_oc', name: 'Turret EM Discharge', tier: OverclockTier.unstable, effect: 'Press reload near turret for AoE discharge, -2 Damage, -5 Magazine Size', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'engineer_stubby_customized_discharge', name: 'Customized Discharge', tier: OverclockTier.balanced, effect: '+15 Magazine Size, -1 Rate of Fire, -1 Damage', icon: 'icon_upgrade_clip_size'),
        ],
      ),
      // ── LOK-1 Smart Rifle (7 OCs) ──
      Weapon(
        id: 'lok1_smart_rifle',
        name: 'LOK-1 Smart Rifle',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'engineer_lok1_eraser', name: 'Eraser', tier: OverclockTier.clean, effect: '+12 Max Locks-On, +33% Lock-On Range', icon: 'icon_upgrade_aim'),
          Overclock(id: 'engineer_lok1_armor_break_module', name: 'Armor Break Module', tier: OverclockTier.clean, effect: '+200% Armor Breaking, +1 Damage vs Armor', icon: 'icon_upgrade_armor_breaking'),
          Overclock(id: 'engineer_lok1_explosive_chemical_rounds', name: 'Explosive Chemical Rounds', tier: OverclockTier.balanced, effect: 'Full lock burst causes AoE explosion, -20% Lock-On Range, -10 Max Ammo', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'engineer_lok1_seeker_rounds', name: 'Seeker Rounds', tier: OverclockTier.balanced, effect: 'Bullets curve around obstacles, -15 Max Ammo, -1 Damage', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'engineer_lok1_executioner', name: 'Executioner', tier: OverclockTier.unstable, effect: '+100% Weakpoint Bonus, +20% Lock-On Speed, -12 Max Locks-On, -20 Max Ammo', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'engineer_lok1_neuro_lasso', name: 'Neuro-Lasso', tier: OverclockTier.unstable, effect: 'Full lock burst Fears targets, -20% Lock-On Speed, -1 Damage', icon: 'icon_overclock_neuro'),
          Overclock(id: 'engineer_lok1_ecm', name: 'ECM', tier: OverclockTier.unstable, effect: 'Press reload to create ECM field that slows, -2 Damage, -10 Magazine Size', icon: 'icon_overclock_slowdown'),
        ],
      ),
      // ── Deepcore 40mm PGL (6 OCs) ──
      Weapon(
        id: 'deepcore_40mm_pgl',
        name: 'Deepcore 40mm PGL',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'engineer_pgl_clean_sweep', name: 'Clean Sweep', tier: OverclockTier.clean, effect: '+10 Area Damage, +0.5m AoE Radius', icon: 'icon_upgrade_area'),
          Overclock(id: 'engineer_pgl_pack_rat', name: 'Pack Rat', tier: OverclockTier.clean, effect: '+2 Max Ammo', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'engineer_pgl_compact_rounds', name: 'Compact Rounds', tier: OverclockTier.balanced, effect: '+4 Max Ammo, -10 Area Damage, -0.5m AoE Radius', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'engineer_pgl_rj250_compound', name: 'RJ250 Compound', tier: OverclockTier.balanced, effect: 'Launcher jump ability, -25 Area Damage', icon: 'icon_upgrade_special'),
          Overclock(id: 'engineer_pgl_fat_boy', name: 'Fat Boy', tier: OverclockTier.unstable, effect: '+300 Area Damage (Radiation), Leaves radiation zone, -70% Max Ammo, -70% AoE Radius', icon: 'icon_upgrade_radioactive'),
          Overclock(id: 'engineer_pgl_hyper_propellant', name: 'Hyper Propellant', tier: OverclockTier.unstable, effect: '+350 Direct Damage, +350% Projectile Velocity, -2 Max Ammo, -70% AoE Radius', icon: 'icon_upgrade_projectile_speed'),
        ],
      ),
      // ── Breach Cutter (7 OCs) ──
      Weapon(
        id: 'breach_cutter',
        name: 'Breach Cutter',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'engineer_bc_light_weight_cases', name: 'Light-Weight Cases', tier: OverclockTier.clean, effect: '+3 Max Ammo, -0.2 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'engineer_bc_roll_control', name: 'Roll Control', tier: OverclockTier.clean, effect: '+25% Beam Width, Beam rotates 90 degrees', icon: 'icon_upgrade_area'),
          Overclock(id: 'engineer_bc_stronger_plasma_current', name: 'Stronger Plasma Current', tier: OverclockTier.balanced, effect: '+50% Beam DPS, -3 Max Ammo', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'engineer_bc_return_to_sender', name: 'Return to Sender', tier: OverclockTier.balanced, effect: 'Beam returns to player, -50% Beam DPS, +50% Projectile Lifetime', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'engineer_bc_high_voltage_crossover', name: 'High Voltage Crossover', tier: OverclockTier.unstable, effect: 'Electrocutes enemies, +33% Beam Width, -2 Max Ammo, -33% Magazine Size', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'engineer_bc_spinning_death', name: 'Spinning Death', tier: OverclockTier.unstable, effect: 'Beam spins and moves slowly, +150% Beam Width, +250% Projectile Lifetime, -50% Beam DPS, -2 Max Ammo', icon: 'icon_overclock_special_magazine'),
          Overclock(id: 'engineer_bc_inferno', name: 'Inferno', tier: OverclockTier.unstable, effect: 'Beam sets enemies on fire, -75% Beam DPS, +100% Projectile Lifetime', icon: 'icon_upgrade_heat'),
        ],
      ),
      // ── Shard Diffractor (5 OCs) ──
      Weapon(
        id: 'shard_diffractor',
        name: 'Shard Diffractor',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'engineer_sd_feedback_loop', name: 'Feedback Loop', tier: OverclockTier.clean, effect: 'Damage increases up to 100% over 2.5s of continuous fire', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'engineer_sd_overdrive_booster', name: 'Overdrive Booster', tier: OverclockTier.balanced, effect: '+2 Area Damage, -50% Beam Instability Penalty', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'engineer_sd_plastcrete_catalyst', name: 'Plastcrete Catalyst', tier: OverclockTier.balanced, effect: '+100% Damage on platforms, -1 Damage', icon: 'icon_upgrade_special'),
          Overclock(id: 'engineer_sd_volatile_impact_reactor', name: 'Volatile Impact Reactor', tier: OverclockTier.unstable, effect: 'Shots create shockwave on impact, -1 Damage, -100 Ammo', icon: 'icon_upgrade_area'),
          Overclock(id: 'engineer_sd_bipolar_carabiner', name: 'Bipolar Carabiner', tier: OverclockTier.unstable, effect: '+2 Damage, Positive charge on reload, -50 Ammo, +50% Overheat', icon: 'icon_upgrade_electricity'),
        ],
      ),
    ],
  ),

  // ════════════════════════════════════════════════════════════════
  // GUNNER (42 OCs)
  // ════════════════════════════════════════════════════════════════
  DwarfCharacter(
    dwarfClass: DwarfClass.gunner,
    name: 'Gunner',
    imagePath: 'assets/images/character/300px-Gunner.webp',
    weapons: [
      // ── "Lead Storm" Powered Minigun (8 OCs) ──
      Weapon(
        id: 'lead_storm_minigun',
        name: '"Lead Storm" Powered Minigun',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'gunner_minigun_a_little_more_oomph', name: 'A Little More Oomph!', tier: OverclockTier.clean, effect: '+1 Damage', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_minigun_thinned_drum_walls', name: 'Thinned Drum Walls', tier: OverclockTier.clean, effect: '+300 Max Ammo, -1s Cooling Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_minigun_burning_hell', name: 'Burning Hell', tier: OverclockTier.balanced, effect: 'Close-range enemies ignite, +50% Heat Generation', icon: 'icon_upgrade_heat'),
          Overclock(id: 'gunner_minigun_compact_mags', name: 'Compact Feed Mechanism', tier: OverclockTier.balanced, effect: '+800 Max Ammo, -1 Damage', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_minigun_exhaust_vectoring', name: 'Exhaust Vectoring', tier: OverclockTier.balanced, effect: '+2 Damage, +150% Base Spread, +50% Heat Generation', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_minigun_bullet_hell', name: 'Bullet Hell', tier: OverclockTier.unstable, effect: '50% ricochet chance, +800 Max Ammo, -3 Damage, +500% Base Spread', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'gunner_minigun_lead_storm', name: 'Lead Storm', tier: OverclockTier.unstable, effect: '+4 Damage while stationary, -80% Movement Speed while firing', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_minigun_carpet_bomber', name: 'Carpet Bomber', tier: OverclockTier.unstable, effect: 'Shots explode on impact, -3 Direct Damage, +3 AoE Damage, -300 Max Ammo', icon: 'icon_upgrade_area_damage'),
        ],
      ),
      // ── "Thunderhead" Heavy Autocannon (7 OCs) ──
      Weapon(
        id: 'thunderhead_autocannon',
        name: '"Thunderhead" Heavy Autocannon',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'gunner_autocannon_composite_drums', name: 'Composite Drums', tier: OverclockTier.clean, effect: '+110 Max Ammo, -0.5 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_autocannon_splintering_shells', name: 'Splintering Shells', tier: OverclockTier.clean, effect: '+1 Area Damage, +0.3m AoE Radius', icon: 'icon_upgrade_area'),
          Overclock(id: 'gunner_autocannon_carpet_bomber', name: 'Carpet Bomber', tier: OverclockTier.balanced, effect: '+3 Area Damage, +0.7m AoE Radius, -7 Direct Damage, -30% Rate of Fire', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'gunner_autocannon_combat_mobility', name: 'Combat Mobility', tier: OverclockTier.balanced, effect: '+50% Movement Speed while firing, +0.2 Reload Time', icon: 'icon_upgrade_speed'),
          Overclock(id: 'gunner_autocannon_big_bertha', name: 'Big Bertha', tier: OverclockTier.unstable, effect: '+12 Direct Damage, -50% Rate of Fire, -110 Max Ammo, -36 Magazine Size', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_autocannon_neurotoxin_payload', name: 'Neurotoxin Payload', tier: OverclockTier.unstable, effect: 'Poisons and slows enemies, -3 Area Damage, -6 Direct Damage', icon: 'icon_upgrade_acid'),
          Overclock(id: 'gunner_autocannon_ntp_compound', name: 'NTP Compound', tier: OverclockTier.unstable, effect: 'Shots Fear enemies, +20 Damage vs Feared, -3 Direct Damage, -2 Area Damage', icon: 'icon_overclock_neuro'),
        ],
      ),
      // ── "Hurricane" Guided Rocket System (8 OCs) ──
      Weapon(
        id: 'hurricane_rocket_system',
        name: '"Hurricane" Guided Rocket System',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'gunner_hurricane_overtuned_feed_mechanism', name: 'Overtuned Feed Mechanism', tier: OverclockTier.clean, effect: '+2 Rate of Fire, +120 Max Ammo', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'gunner_hurricane_fragmentation_missiles', name: 'Fragmentation Missiles', tier: OverclockTier.clean, effect: '+1 Area Damage, +0.5m AoE Radius', icon: 'icon_upgrade_area'),
          Overclock(id: 'gunner_hurricane_pressure_wave', name: 'Pressure Wave', tier: OverclockTier.balanced, effect: '+3 Area Damage, +0.5m AoE Radius, -2 Direct Damage', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'gunner_hurricane_napalm_missiles', name: 'Napalm Missiles', tier: OverclockTier.balanced, effect: 'Rockets set enemies on fire, -2 Direct Damage, -2 Area Damage', icon: 'icon_upgrade_heat'),
          Overclock(id: 'gunner_hurricane_minelayer_system', name: 'Minelayer System', tier: OverclockTier.unstable, effect: 'Rockets act as proximity mines, -72 Max Ammo, -36 Magazine Size', icon: 'icon_overclock_special_magazine'),
          Overclock(id: 'gunner_hurricane_jet_fuel_homebrew', name: 'Jet Fuel Homebrew', tier: OverclockTier.unstable, effect: '+50% Direct Damage, +100% Projectile Velocity, -50 Max Ammo, -50% AoE Radius', icon: 'icon_upgrade_projectile_speed'),
          Overclock(id: 'gunner_hurricane_salvo_module', name: 'Salvo Module', tier: OverclockTier.unstable, effect: 'Fires 9 rockets in a burst, -50% Rate of Fire, -72 Max Ammo', icon: 'icon_upgrade_special'),
          Overclock(id: 'gunner_hurricane_rocket_barrage', name: 'Rocket Barrage', tier: OverclockTier.balanced, effect: '+144 Max Ammo, -2 Direct Damage, -50% Turn Rate', icon: 'icon_upgrade_ammo'),
        ],
      ),
      // ── "Bulldog" Heavy Revolver (6 OCs) ──
      Weapon(
        id: 'bulldog_revolver',
        name: '"Bulldog" Heavy Revolver',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'gunner_bulldog_homebrew_powder', name: 'Homebrew Powder', tier: OverclockTier.clean, effect: 'Damage randomly between x0.8 and x1.4', icon: 'icon_overclock_change_of_higher_damage'),
          Overclock(id: 'gunner_bulldog_chain_hit', name: 'Chain Hit', tier: OverclockTier.balanced, effect: '75% chance to ricochet, -24 Max Ammo', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'gunner_bulldog_volatile_bullets', name: 'Volatile Bullets', tier: OverclockTier.unstable, effect: '+300% Damage vs Burning enemies, -10 Damage', icon: 'icon_upgrade_heat'),
          Overclock(id: 'gunner_bulldog_six_shooter', name: 'Six Shooter', tier: OverclockTier.balanced, effect: '+2 Rate of Fire, +8 Max Ammo, -2 Damage', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'gunner_bulldog_elephant_rounds', name: 'Elephant Rounds', tier: OverclockTier.unstable, effect: '+100% Damage, -13 Max Ammo, +71% Spread, +150% Recoil, -50% Weakpoint Bonus', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_bulldog_magic_bullets', name: 'Magic Bullets', tier: OverclockTier.unstable, effect: 'Bullets home to weakpoints, -20% Damage, -4 Max Ammo', icon: 'icon_upgrade_aim'),
        ],
      ),
      // ── BRT7 Burst Fire Gun (7 OCs) ──
      Weapon(
        id: 'brt7_burst_fire',
        name: 'BRT7 Burst Fire Gun',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'gunner_brt7_composite_casings', name: 'Composite Casings', tier: OverclockTier.clean, effect: '+36 Max Ammo, +1 Rate of Fire', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_brt7_full_chamber_seal', name: 'Full Chamber Seal', tier: OverclockTier.clean, effect: '+1 Damage, -0.2 Reload Time', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_brt7_compact_mags', name: 'Compact Mags', tier: OverclockTier.balanced, effect: '+84 Max Ammo, -1 Rate of Fire, +0.4 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_brt7_experimental_rounds', name: 'Experimental Rounds', tier: OverclockTier.balanced, effect: '+9 Damage, -6 Magazine Size, -36 Max Ammo', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'gunner_brt7_electro_minelets', name: 'Electro Minelets', tier: OverclockTier.unstable, effect: 'Bullets leave electric mines, -1 Damage, -6 Magazine Size', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'gunner_brt7_micro_flechettes', name: 'Micro Flechettes', tier: OverclockTier.unstable, effect: '+120 Max Ammo, -3 Damage, +100% Weakpoint Bonus', icon: 'icon_upgrade_aim'),
          Overclock(id: 'gunner_brt7_lead_spray', name: 'Lead Spray', tier: OverclockTier.unstable, effect: 'Fires 12 pellets (shotgun), -50% Weakpoint Bonus, +100% Spread', icon: 'icon_upgrade_shotgun_blast'),
        ],
      ),
      // ── ArmsKore Coil Gun (6 OCs) ──
      Weapon(
        id: 'armskore_coil_gun',
        name: 'ArmsKore Coil Gun',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'gunner_coilgun_re_atomizer', name: 'Re-Atomizer', tier: OverclockTier.clean, effect: '+40 Ammo, +0.4m Trail AoE Radius', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_coilgun_ultra_magnetic', name: 'Ultra-Magnetic', tier: OverclockTier.clean, effect: '+50% Charge Speed, Reduces Charge Shot Base Spread', icon: 'icon_upgrade_aim'),
          Overclock(id: 'gunner_coilgun_backfeeding_module', name: 'Backfeeding Module', tier: OverclockTier.balanced, effect: 'Regain ammo on overkill damage, -2 Direct Damage', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'gunner_coilgun_the_mole', name: 'The Mole', tier: OverclockTier.balanced, effect: 'Shots penetrate terrain, -10 Ammo, -50% Charge Speed', icon: 'icon_upgrade_special'),
          Overclock(id: 'gunner_coilgun_hellfire', name: 'Hellfire', tier: OverclockTier.unstable, effect: 'Trail sets enemies on fire, +40 Ammo, -50% Direct Damage, +100% Trail Duration', icon: 'icon_upgrade_heat'),
          Overclock(id: 'gunner_coilgun_triple_tech_chambers', name: 'Triple-Tech Chambers', tier: OverclockTier.unstable, effect: '+350% Fully Charged Damage, Fully charged shots consume 2 ammo, -20 Ammo', icon: 'icon_upgrade_damage_general'),
        ],
      ),
    ],
  ),

  // ════════════════════════════════════════════════════════════════
  // SCOUT (40 OCs)
  // ════════════════════════════════════════════════════════════════
  DwarfCharacter(
    dwarfClass: DwarfClass.scout,
    name: 'Scout',
    imagePath: 'assets/images/character/300px-Scout.webp',
    weapons: [
      // ── Deepcore GK2 (8 OCs) ──
      Weapon(
        id: 'deepcore_gk2',
        name: 'Deepcore GK2',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'scout_gk2_compact_ammo', name: 'Compact Ammo', tier: OverclockTier.clean, effect: '+5 Magazine Size, +100 Max Ammo', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'scout_gk2_gas_rerouting', name: 'Gas Rerouting', tier: OverclockTier.clean, effect: '+1 Rate of Fire, -0.3s Reload Time', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'scout_gk2_homebrew_powder', name: 'Homebrew Powder', tier: OverclockTier.clean, effect: 'Damage randomly between x0.8 and x1.4', icon: 'icon_overclock_change_of_higher_damage'),
          Overclock(id: 'scout_gk2_overclocked_firing_mechanism', name: 'Overclocked Firing Mechanism', tier: OverclockTier.balanced, effect: '+3 Rate of Fire, -50 Max Ammo, +100% Recoil', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'scout_gk2_bullets_of_mercy', name: 'Bullets of Mercy', tier: OverclockTier.balanced, effect: '+33% Damage on status-affected enemies, -5 Magazine Size', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'scout_gk2_ai_stability_engine', name: 'AI Stability Engine', tier: OverclockTier.unstable, effect: '+40% Weakpoint Bonus, No Recoil, -2 Rate of Fire, -2 Damage', icon: 'icon_upgrade_aim'),
          Overclock(id: 'scout_gk2_electrifying_reload', name: 'Electrifying Reload', tier: OverclockTier.unstable, effect: 'Electric reload (AoE electrocute), -5 Magazine Size, -50 Max Ammo', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'scout_gk2_battle_cool', name: 'Battle Cool', tier: OverclockTier.balanced, effect: '-75% Spread while moving, +1 Damage, -10 Magazine Size', icon: 'icon_upgrade_aim'),
        ],
      ),
      // ── M1000 Classic (7 OCs) ──
      Weapon(
        id: 'm1000_classic',
        name: 'M1000 Classic',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'scout_m1000_hoverclock', name: 'Hoverclock', tier: OverclockTier.clean, effect: 'Focused shot hovers in air, -20 Max Ammo', icon: 'icon_upgrade_special'),
          Overclock(id: 'scout_m1000_minimal_clips', name: 'Minimal Clips', tier: OverclockTier.clean, effect: '+16 Max Ammo, -0.4 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'scout_m1000_active_stability_system', name: 'Active Stability System', tier: OverclockTier.balanced, effect: '+70% Focus Speed, +20% Focused Shot Damage, -20 Max Ammo', icon: 'icon_upgrade_aim'),
          Overclock(id: 'scout_m1000_hipster', name: 'Hipster', tier: OverclockTier.balanced, effect: '+3 Rate of Fire, -14 Max Ammo, -25% Focus Speed, +175% Recoil', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'scout_m1000_electrocuting_focus_shots', name: 'Electrocuting Focus Shots', tier: OverclockTier.unstable, effect: 'Focused shot electrocutes target, -25% Focus Shot Damage', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'scout_m1000_supercooling_chamber', name: 'Supercooling Chamber', tier: OverclockTier.unstable, effect: '+125% Focused Shot Damage, -37 Max Ammo, -50% Focus Speed, Cannot Hipfire', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'scout_m1000_disincentive_magazine', name: 'Disincentive Magazine', tier: OverclockTier.balanced, effect: 'Focused shots slow targets 80%, +8 Max Ammo, -1 Damage', icon: 'icon_overclock_slowdown'),
        ],
      ),
      // ── DRAK-25 Plasma Carbine (8 OCs) ──
      Weapon(
        id: 'drak25_plasma_carbine',
        name: 'DRAK-25 Plasma Carbine',
        isPrimary: true,
        overclocks: [
          Overclock(id: 'scout_drak_aggressive_venting', name: 'Aggressive Venting', tier: OverclockTier.clean, effect: 'Overheat creates AoE heat burst, +50% Cooling Rate', icon: 'icon_upgrade_heat'),
          Overclock(id: 'scout_drak_thermal_feedback', name: 'Thermal Feedback', tier: OverclockTier.clean, effect: 'Damage increases with heat level (up to +50%)', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'scout_drak_impact_deflection', name: 'Impact Deflection', tier: OverclockTier.balanced, effect: 'Projectiles ricochet off armor and terrain, -1 Damage, -1 Rate of Fire', icon: 'icon_upgrade_ricoshet'),
          Overclock(id: 'scout_drak_overtuned_particle_accelerator', name: 'Overtuned Particle Accelerator', tier: OverclockTier.balanced, effect: '+8 Damage, No Weakpoint Bonus, +100% Base Spread, -50% Cooling Rate', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'scout_drak_rewiring_mod', name: 'Rewiring Mod', tier: OverclockTier.balanced, effect: '+2 Electric Damage, +2 Rate of Fire, -100 Battery Capacity', icon: 'icon_upgrade_electricity'),
          Overclock(id: 'scout_drak_shield_battery_booster', name: 'Shield Battery Booster', tier: OverclockTier.unstable, effect: '+50% Shield Recharge Rate while firing, -2 Damage, +50% Heat per Shot', icon: 'icon_upgrade_special'),
          Overclock(id: 'scout_drak_thermal_exhaust_feedback', name: 'Thermal Exhaust Feedback', tier: OverclockTier.unstable, effect: 'Overheat triggers damage burst, +100% Heat per Shot, -100 Battery Capacity', icon: 'icon_upgrade_heat'),
          Overclock(id: 'scout_drak_bouncy_plasma', name: 'Bouncy Plasma', tier: OverclockTier.unstable, effect: 'Projectiles bounce off terrain, -1 Damage, -50% Projectile Velocity', icon: 'icon_upgrade_ricoshet'),
        ],
      ),
      // ── Jury-Rigged Boomstick (6 OCs) ──
      Weapon(
        id: 'jury_rigged_boomstick',
        name: 'Jury-Rigged Boomstick',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'scout_boomstick_compact_shells', name: 'Compact Shells', tier: OverclockTier.clean, effect: '+6 Max Ammo, -0.2 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'scout_boomstick_double_barrel', name: 'Double Barrel', tier: OverclockTier.clean, effect: 'Fire both barrels at once, +1 Damage', icon: 'icon_upgrade_shotgun_blast'),
          Overclock(id: 'scout_boomstick_special_powder', name: 'Special Powder', tier: OverclockTier.balanced, effect: 'Shooting propels you (shotgun jump), -50% Magazine Size', icon: 'icon_upgrade_special'),
          Overclock(id: 'scout_boomstick_stuffed_shells', name: 'Stuffed Shells', tier: OverclockTier.balanced, effect: '+2 Damage, -6 Max Ammo', icon: 'icon_upgrade_damage_general'),
          Overclock(id: 'scout_boomstick_shaped_shells', name: 'Shaped Shells', tier: OverclockTier.unstable, effect: '-50% Base Spread, +35% Weakpoint Bonus, -6 Max Ammo, -1 Damage', icon: 'icon_upgrade_aim'),
          Overclock(id: 'scout_boomstick_jumbo_shells', name: 'Jumbo Shells', tier: OverclockTier.unstable, effect: '+8 Damage, -10 Max Ammo, +50% Recoil', icon: 'icon_upgrade_damage_general'),
        ],
      ),
      // ── Zhukov NUK17 (5 OCs) ──
      Weapon(
        id: 'zhukov_nuk17',
        name: 'Zhukov NUK17',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'scout_zhukov_minimal_magazines', name: 'Minimal Magazines', tier: OverclockTier.clean, effect: '+75 Max Ammo, -0.4 Reload Time', icon: 'icon_upgrade_ammo'),
          Overclock(id: 'scout_zhukov_custom_casings', name: 'Custom Casings', tier: OverclockTier.balanced, effect: '+30 Max Ammo, +1 Rate of Fire, -2 Damage', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'scout_zhukov_cryo_minelets', name: 'Cryo Minelets', tier: OverclockTier.unstable, effect: 'Shots leave cryo minelets on surfaces, -1 Damage, -10 Magazine Size', icon: 'icon_upgrade_cold'),
          Overclock(id: 'scout_zhukov_embedded_detonators', name: 'Embedded Detonators', tier: OverclockTier.unstable, effect: 'Reload detonates embedded bullets, -6 Damage, -20 Magazine Size, -400 Max Ammo', icon: 'icon_upgrade_area_damage'),
          Overclock(id: 'scout_zhukov_gas_recycling', name: 'Gas Recycling', tier: OverclockTier.balanced, effect: '+5 Damage, No Weakpoint Bonus', icon: 'icon_upgrade_damage_general'),
        ],
      ),
      // ── Nishanka Boltshark X-80 (6 OCs) ──
      Weapon(
        id: 'nishanka_boltshark_x80',
        name: 'Nishanka Boltshark X-80',
        isPrimary: false,
        overclocks: [
          Overclock(id: 'scout_boltshark_quick_fire', name: 'Quick Fire', tier: OverclockTier.clean, effect: '-0.2 Reload Time, +10 Max Ammo', icon: 'icon_upgrade_fire_rate'),
          Overclock(id: 'scout_boltshark_the_specialist', name: 'The Specialist', tier: OverclockTier.clean, effect: '+30% Weakpoint Bonus, +15% Focus Speed', icon: 'icon_upgrade_aim'),
          Overclock(id: 'scout_boltshark_cryo_bolt', name: 'Cryo Bolt', tier: OverclockTier.balanced, effect: 'Bolts freeze enemies, -10 Direct Damage, -10 Max Ammo', icon: 'icon_upgrade_cold'),
          Overclock(id: 'scout_boltshark_fire_bolt', name: 'Fire Bolt', tier: OverclockTier.balanced, effect: 'Bolts set enemies on fire (AoE), -10 Direct Damage, -10 Max Ammo', icon: 'icon_upgrade_heat'),
          Overclock(id: 'scout_boltshark_bodkin_points', name: 'Bodkin Points', tier: OverclockTier.unstable, effect: '+100% Armor Breaking, +20% Weakpoint Bonus, -30 Direct Damage', icon: 'icon_upgrade_armor_breaking'),
          Overclock(id: 'scout_boltshark_trifork_volley', name: 'Trifork Volley', tier: OverclockTier.unstable, effect: 'Fires 3 bolts, -33% Direct Damage per bolt, +5 Max Ammo', icon: 'icon_upgrade_shotgun_blast'),
        ],
      ),
    ],
  ),
];
