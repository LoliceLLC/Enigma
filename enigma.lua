local Enigma = {}

local CoreHero = Heroes.GetLocal()
local IsEnigma = false
if (CoreHero) then
    IsEnigma = NPC.GetUnitName(CoreHero) == 'npc_dota_hero_enigma'
end
HeroesCore.UseCurrentPath(IsEnigma)

Enigma.MainEnable = HeroesCore.AddOptionBool({ 'Hero Specific', 'Intelligence',  'Enigma' }, 'Enable', false)
HeroesCore.AddOptionIcon(Enigma.MainEnable, '~/MenuIcons/Enable/enable_check_boxed.png')
HeroesCore.AddMenuIcon({ 'Hero Specific', 'Intelligence', 'Enigma' }, 'panorama/images/heroes/icons/npc_dota_hero_enigma_png.vtex_c')

Enigma.BlackHoleComboBind = HeroesCore.AddKeyOption({ 'Hero Specific', 'Intelligence',  'Enigma' }, 'BlackHole combo', Enum.ButtonCode.KEY_NONE)
HeroesCore.AddOptionIcon(Enigma.BlackHoleComboBind, '~/MenuIcons/box_drop.png')

Enigma.AbilitiesForBlackHoleCombo = HeroesCore.AddOptionMultiSelect({ 'Hero Specific', 'Intelligence', 'Enigma' }, 'Skills:',
{
    { 'midnight_pulse', 'panorama/images/spellicons/enigma_midnight_pulse_png.vtex_c', true },
    { 'black_hole', 'panorama/images/spellicons/enigma_black_hole_png.vtex_c', true }
}, false)
HeroesCore.AddOptionIcon(Enigma.AbilitiesForBlackHoleCombo, '~/MenuIcons/dots.png')

Enigma.ItemsForBlackHoleCombo = HeroesCore.AddOptionMultiSelect({ 'Hero Specific', 'Intelligence', 'Enigma' }, 'Items:',
{
    { 'item_soul_ring', 'panorama/images/items/soul_ring_png.vtex_c', true },
    { 'item_gungir', 'panorama/images/items/gungir_png.vtex_c', true },
    { 'item_veil_of_discord', 'panorama/images/items/veil_of_discord_png.vtex_c', true },
    { 'item_shivas_guard', 'panorama/images/items/shivas_guard_png.vtex_c', true },
    { 'item_ancient_janggo', 'panorama/images/items/ancient_janggo_png.vtex_c', true },
    { 'item_boots_of_bearing', 'panorama/images/items/boots_of_bearing_png.vtex_c', true },
    { 'item_bloodstone', 'panorama/images/items/bloodstone_png.vtex_c', true },
    { 'item_black_king_bar', 'panorama/images/items/black_king_bar_png.vtex_c', false }
}, false)
HeroesCore.AddOptionIcon(Enigma.ItemsForBlackHoleCombo, '~/MenuIcons/dots.png')

Enigma.ItemsForBlackHoleCombo = HeroesCore.AddOptionMultiSelect({ 'Hero Specific', 'Intelligence', 'Enigma' }, 'Item123:', HeroesCore.ItemsUsage, false)

Enigma.UseRefresherEnable = HeroesCore.AddOptionBool({ 'Hero Specific', 'Intelligence',  'Enigma' }, 'Use refresher in combo', false)
HeroesCore.AddOptionIcon(Enigma.UseRefresherEnable, 'panorama/images/items/refresher_png.vtex_c')
Menu.AddOptionTip(Enigma.UseRefresherEnable, 'RefresherShard in priority!')

Enigma.MinimumHeroesForBlackHoleCombo = HeroesCore.AddOptionSlider({ 'Hero Specific', 'Intelligence',  'Enigma' }, 'Minimum heroes for BlackHole', 1, 5, 3)
HeroesCore.AddOptionIcon(Enigma.MinimumHeroesForBlackHoleCombo, '~/MenuIcons/people.png')

Enigma.DrawBestPositionEnable = HeroesCore.AddOptionBool({ 'Hero Specific', 'Intelligence',  'Enigma' }, 'Draw best position for ult', false)
HeroesCore.AddOptionIcon(Enigma.DrawBestPositionEnable, '~/MenuIcons/map_points.png')

-- после фикса рендера амбреллы я в душе не ебу чё и как рендерить шрифты. работает по кайфу
local Font = Renderer.LoadFont(fioesdjfoirwsjmfgsrjkios, 1337)

local Timer = -69696969
local GameTime = nil

local MyHero = nil
local MyTeam = nil
local MyMana = nil

local MidnightPulse = nil
local BlackHole = nil

local Counter = 0
local DrawedParticle = false
local ParticleHandler = nil

function Enigma.Init()
    if (Engine.IsInGame()) then
        if (IsEnigma) then
            MyHero = Heroes.GetLocal()
            MyTeam = Entity.GetTeamNum(MyHero)
        end
    end
end

Enigma.Init()

function Enigma.OnGameStart()
    Enigma.Init()
end

function Enigma.UpdateInfo()
    MyMana = NPC.GetMana(MyHero)
    MidnightPulse = NPC.GetAbility(MyHero, 'enigma_midnight_pulse')
    BlackHole = NPC.GetAbility(MyHero, 'enigma_black_hole')

    BlinkRadius = Ability.GetCastRange(Enigma.GetBlink(MyHero))
end

function Enigma.GetBlink(MyHero)
    DefaultBlink = NPC.GetItem(MyHero, "item_blink")
    OverwhelmingBlink = NPC.GetItem(MyHero, "item_overwhelming_blink")
    ArcaneBlink = NPC.GetItem(MyHero, "item_arcane_blink")
    SwiftBlink = NPC.GetItem(MyHero, "item_swift_blink")

    if (Ability.IsReady(DefaultBlink)) then
        Blink = DefaultBlink
    end

    if (Ability.IsReady(OverwhelmingBlink)) then
        Blink = OverwhelmingBlink
    end

    if (Ability.IsReady(ArcaneBlink)) then
        Blink = ArcaneBlink
    end

    if (Ability.IsReady(SwiftBlink)) then
        Blink = SwiftBlink
    end

    return Blink
end

function Enigma.BestUltimatePosition(UnitsAround, Radius)
    if (not UnitsAround or #UnitsAround <= 0) then return nil end

    local EnemyNumber = #UnitsAround

	if (EnemyNumber == 1) then return Entity.GetAbsOrigin(UnitsAround[1]) end

	local MaxNumber = 1
	local BestPos = Entity.GetAbsOrigin(UnitsAround[1])

	for i = 1, EnemyNumber-1 do
		for j = i+1, EnemyNumber do
			if (UnitsAround[i] and UnitsAround[j]) then
				local Pos1 = Entity.GetAbsOrigin(UnitsAround[i])
				local Pos2 = Entity.GetAbsOrigin(UnitsAround[j])
				local Mid = Pos1:__add(Pos2):Scaled(0.5)

				local HeroesNumber = 0

				for k = 1, EnemyNumber do
					if (NPC.IsPositionInRange(UnitsAround[k], Mid, Radius, 0)) then
						HeroesNumber = HeroesNumber + 1
					end
				end

				if (HeroesNumber > MaxNumber) then
					MaxNumber = HeroesNumber
					BestPos = Mid
				end
			end
		end
	end
	return BestPos
end

function Enigma.OnUpdate()

    if (MyHero == nil) then return end
    if (not IsEnigma) then return end

    -- Ekanio thanks =)
    if (Menu.IsEnabled(Enigma.MainEnable)) then
        if (Menu.IsEnabled(Enigma.DrawBestPositionEnable)) then
            if (Counter >= 1 and Ability.IsReady(BlackHole) and Ability.GetLevel(BlackHole) > 0 and DrawedParticle == false) then
                ParticleHandler = Particle.Create("particles/ui_mouseactions/range_display.vpcf")
                DrawedParticle = true
            end
        end

        if (Menu.IsEnabled(Enigma.DrawBestPositionEnable)) then
            if (Ability.IsReady(BlackHole) and Ability.GetLevel(BlackHole) > 0) then
                local EnemySearchRadius = 1200 + BlinkRadius
                local EnemyHeroes = Entity.GetHeroesInRadius(MyHero, EnemySearchRadius, Enum.TeamType.TEAM_ENEMY)
                local PositionForParticle = Enigma.BestUltimatePosition(EnemyHeroes, 425)

                if (PositionForParticle) then
                    local _x, _y = Renderer.WorldToScreen(PositionForParticle)

                    Counter = 0

                    local EnemiesUnderBlackHole = Heroes.InRadius(PositionForParticle, 425, MyTeam, Enum.TeamType.TEAM_ENEMY)

                    for _, Enemy in pairs(EnemiesUnderBlackHole) do
                        if (Enemy ~= nil and Entity.IsHero(Enemy) and not Entity.IsSameTeam(MyHero, Enemy) and Entity.IsAlive(Enemy) and not Entity.IsDormant(Enemy) and not NPC.IsIllusion(Enemy)) then
                            Counter = Counter + 1
                        end
                    end

                    if (Counter >= Menu.GetValue(Enigma.MinimumHeroesForBlackHoleCombo)) then
                        Particle.SetControlPoint(ParticleHandler, 0, PositionForParticle)
                        Particle.SetControlPoint(ParticleHandler, 1, Vector(380,0,0))
                        Renderer.SetDrawColor(255, 255, 255, 225)
                        Renderer.DrawText(Font, _x - 10, _y - 10, Counter)
                    else
                        if (DrawedParticle) then
                            Particle.Destroy(ParticleHandler)
                            DrawedParticle = false
                        end
                    end
                else
                    if (DrawedParticle) then
                        Particle.Destroy(ParticleHandler)
                        DrawedParticle = false
                    end
                end
            else
                if (DrawedParticle) then
                    Particle.Destroy(ParticleHandler)
                    DrawedParticle = false
                end
            end
        else
            if (DrawedParticle) then
                Particle.Destroy(ParticleHandler)
                DrawedParticle = false
            end
        end
    else
        if (DrawedParticle) then
            Particle.Destroy(ParticleHandler)
            DrawedParticle = false
        end
    end

    GameTime = GameRules.GetGameTime()
    if (Timer > GameTime) then return end
    Timer = HeroesCore.GetSleep(0.1)

    Enigma.UpdateInfo()

    if not Entity.IsAlive(MyHero)
    or NPC.HasState(MyHero, Enum.ModifierState.MODIFIER_STATE_SILENCED)
    or NPC.HasState(MyHero, Enum.ModifierState.MODIFIER_STATE_MUTED)
    or NPC.HasState(MyHero, Enum.ModifierState.MODIFIER_STATE_STUNNED)
    or NPC.HasState(MyHero, Enum.ModifierState.MODIFIER_STATE_HEXED)
    or NPC.HasState(MyHero, Enum.ModifierState.MODIFIER_STATE_NIGHTMARED)
    or NPC.HasModifier(MyHero, 'modifier_obsidian_destroyer_astral_imprisonment_prison')
    or NPC.HasModifier(MyHero, 'modifier_teleporting')
    or NPC.HasModifier(MyHero, 'modifier_pudge_swallow_hide')
    or NPC.HasModifier(MyHero, 'modifier_axe_berserkers_call')
    then return end

    if (Menu.IsEnabled(Enigma.MainEnable)) then

        local BlackHoleComboStep = 0
        local CastPos = Enigma.BestUltimatePosition(Entity.GetHeroesInRadius(MyHero, 1200 + BlinkRadius, Enum.TeamType.TEAM_ENEMY), 425)

        -- BlackHole combo
        if (Menu.IsKeyDown(Enigma.BlackHoleComboBind)) then
            if (CastPos) then
                if (Counter >= Menu.GetValue(Enigma.MinimumHeroesForBlackHoleCombo)) then

                    -- Use refresher
                    if (not Ability.IsReady(BlackHole)) then
                        if (Menu.IsEnabled(Enigma.UseRefresherEnable)) then
                            if (not Ability.IsInAbilityPhase(NPC.GetAbilityByIndex(MyHero, 5))) then
                                if (not Ability.IsChannelling(NPC.GetAbilityByIndex(MyHero, 5))) then
                                    if (Ability.IsCastable(NPC.GetItem(MyHero, 'item_refresher'), MyMana) or Ability.IsCastable(NPC.GetItem(MyHero, 'item_refresher_shard'), MyMana)) then
                                        Ability.CastNoTarget(NPC.GetItem(MyHero, 'item_refresher_shard'))
                                        Ability.CastNoTarget(NPC.GetItem(MyHero, 'item_refresher'))
                                    end
                                end
                            end
                        end
                    end

                    if (not Ability.IsReady(BlackHole)) then return end

                    -- Use BlackKingBar
                    if (BlackHoleComboStep == 0) then
                        if (Ability.IsCastable(NPC.GetItem(MyHero, 'item_black_king_bar'), MyMana) and (Menu.IsSelected(Enigma.ItemsForBlackHoleCombo, 'item_black_king_bar'))) then
                            Ability.CastNoTarget(NPC.GetItem(MyHero, 'item_black_king_bar'))
                        else
                            BlackHoleComboStep = 1
                        end
                    end

                    -- Use Blink
                    if (BlackHoleComboStep == 1) then
                        if (Ability.IsCastable(Enigma.GetBlink(MyHero), MyMana)) then
                            Ability.CastPosition(Enigma.GetBlink(MyHero), CastPos)
                        else
                            BlackHoleComboStep = 2
                        end
                    end

                    -- Use Items
                    if (BlackHoleComboStep == 2) then
                        -- это сколько бпм в секунду???
                        for _, Items in ipairs(Menu.GetItems(Enigma.ItemsForBlackHoleCombo)) do
                            if (Menu.IsSelected(Enigma.ItemsForBlackHoleCombo, Items)) then
                                if (Ability.IsCastable(NPC.GetItem(MyHero, tostring(Items)), MyMana)) then
                                    if (Items == 'item_black_king_bar') then
                                        break
                                    end
                                    if (Items == 'item_shivas_guard' or Items == 'item_ancient_janggo' or Items == 'item_boots_of_bearing' or Items == 'item_bloodstone') then
                                        Ability.CastNoTarget(NPC.GetItem(MyHero, tostring(Items)))
                                    else
                                        Ability.CastPosition(NPC.GetItem(MyHero, tostring(Items)), CastPos)
                                    end
                                else
                                    BlackHoleComboStep = 3
                                end
                            end
                        end
                    end

                    -- Use MidnightPulse
                    if (BlackHoleComboStep == 3) then
                        if (Ability.IsCastable(MidnightPulse, MyMana) and Menu.IsSelected(Enigma.AbilitiesForBlackHoleCombo, 'midnight_pulse')) then
                            for _, Heroes in pairs(Heroes.InRadius(Entity.GetOrigin(MyHero), 750, Entity.GetTeamNum(MyTeam), Enum.TeamType.TEAM_ENEMY)) do
                                if (not NPC.HasModifier(Heroes, 'modifier_enigma_midnight_pulse_damage')) then
                                    if (not Ability.IsInAbilityPhase(NPC.GetAbilityByIndex(MyHero, 5))) then
                                        if (not Ability.IsChannelling(NPC.GetAbilityByIndex(MyHero, 5))) then
                                            Ability.CastPosition(MidnightPulse, CastPos)
                                        end
                                    end
                                else
                                    BlackHoleComboStep = 4
                                end
                            end
                        else
                            BlackHoleComboStep = 4
                        end
                    end

                    -- Use BlackHole
                    if (BlackHoleComboStep == 4) then
                        if (Ability.IsCastable(BlackHole, MyMana) and Menu.IsSelected(Enigma.AbilitiesForBlackHoleCombo, 'black_hole')) then
                            Ability.CastPosition(BlackHole, CastPos)
                        else
                            BlackHoleComboStep = 5
                        end
                    end
                end
            end
        end
    end
end

return Enigma