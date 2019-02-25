if SERVER then
  AddCSLuaFile( "shared.lua" )
  resource.AddFile( "materials/vgui/ttt/icon_timer.vmt" )
  resource.AddFile( "sound/gamefreak/evillaugh.mp3" )
  resource.AddWorkshop( "899488990" )

  local PLAYER = FindMetaTable("Player")
  util.AddNetworkString( "ColoredMessage" )
  function BroadcastMsg(...)
    local args = {...}
    net.Start("ColoredMessage")
    net.WriteTable(args)
    net.Broadcast()
  end

  function PLAYER:PlayerMsg(...)
    local args = {...}
    net.Start("ColoredMessage")
    net.WriteTable(args)
    net.Send(self)
  end
end

if CLIENT then
  SWEP.PrintName = "Mirror Fate"
  SWEP.Author = "Lord KhrumoX / Gamefreak / Keksgesicht"
  SWEP.Slot = 9
  SWEP.Icon = "vgui/ttt/icon_timer"
  SWEP.EquipMenuData = {
    type = "item_weapon",
    name = "Mirror Fate",
    desc = "If you get killed, your assassin will get a lot of damage! \nIf your assassin has this item too,\nit will have no effect.\nLeft-/Right-Click to adjust the death.\nReload to Reset!"
  }
  net.Receive("ColoredMessage",function(len)
      local msg = net.ReadTable()
      chat.AddText(unpack(msg))
      chat.PlaySound()
    end)
end

SWEP.ViewModel = "models/weapons/cstrike/c_eq_smokegrenade.mdl"
SWEP.WorldModel = "models/weapons/w_eq_smokegrenade.mdl"

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR,ROLE_DETECTIVE}
SWEP.ViewModelFlip = true
SWEP.AutoSpawnable = false

SWEP.AmmoEnt = "nil"

SWEP.InLoadoutFor = { nil }

function SWEP:OnDrop()
  self:Remove()
end

SWEP.AllowDrop = false

SWEP.IsSilent = false

SWEP.NoSights = false
if CLIENT then
  function SWEP:PrimaryAttack() end
  function SWEP:SecondaryAttack() end
  function SWEP:Reload() end
end

if SERVER then

  function SWEP:WasBought(buyer)
    if IsValid(buyer) then
      buyer.fatemode = 1
      buyer.fatetime = 50
    end
  end
  
  function SWEP:Initialize()
    if IsValid(self.Owner) then
      self.Owner.fatemode = 1
      self.Owner.fatetime = 50
    end
  end
  
  function SWEP:PrimaryAttack()
    local ply = self.Owner
    ply.fatetime = ply.fatetime + 10
    if ply.fatetime > 90 then
      ply.fatetime = 20
    end
    ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"The Fate will now take " .. ply.fatetime .. " seconds!")
  end
  
  function SWEP:SecondaryAttack()
    local ply = self.Owner
    ply.fatemode = ply.fatemode + 1
    if ply.fatemode > 3 then
      ply.fatemode = 1
    end
    if ply.fatemode == 1 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will have a heart-attack!")
    elseif ply.fatemode == 2 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will explode!")
    elseif ply.fatemode == 3 then
      ply:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer will burn in Hell!")
    end
  end
  
  function KillTheKillerMirrorfate( victim, killer, damageinfo )
    if IsValid(killer) and IsValid(victim) then
      if killer != victim then
		if killer.DyeOnFate == false then
          if victim:HasWeapon("weapon_ttt_mirrorfate")then
			killer.DyeOnFate = true
			TTTMirrorfateKillHim(victim, killer)
		  end
        end
      elseif victim.DyeOnFate == true then
        victim.DyeOnFate = false
      end
    end
  end
  
  function TTTMirrorfateKillHim(victim, killer)  
    timer.Create( "MirrorFatekill" .. killer:EntIndex(), victim.fatetime , 1, function()
        if IsValid(killer) then
          if killer:Alive() and killer:IsTerror() and killer.DyeOnFate == true then
            if victim.fatemode == 1 then
              local dmginfo = DamageInfo()
              dmginfo:SetDamage(victim.fatetime * 1.23)
              dmginfo:SetAttacker(victim)
              dmginfo:SetDamageType(DMG_GENERIC)
              killer:TakeDamageInfo(dmginfo)
            elseif victim.fatemode == 2 then
              local effectdata = EffectData()
              killer:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
              util.BlastDamage( victim, victim, killer:GetPos() , 200 , victim.fatetime * 1.23)
              effectdata:SetStart( killer:GetPos() + Vector(0,0,10) )
              effectdata:SetOrigin( killer:GetPos() + Vector(0,0,10) )
              effectdata:SetScale( 1 )
              util.Effect( "HelicopterMegaBomb", effectdata )
            elseif victim.fatemode == 3 then
              killer:EmitSound("gamefreak/evillaugh.mp3")
              timer.Create("BurnInHellMirrorfate" .. killer:EntIndex(), 0.2, victim.fatetime * 1.23, function()
                  if killer:Alive() and killer:IsTerror() and IsValid(killer) then
                    killer:Ignite(0.2)
                  elseif IsValid(killer) and !killer:IsTerror() then
                    timer.Remove("BurnInHellMirrorfate" .. killer:EntIndex())
                  end
                end )
            end
            killer:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"You have shared the " ,Color(255,0,0) ,"fate " ,Color(250,250,250) ,"your victim had choosed." )
            victim:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer have shared your " ,Color(255,0,0), "fate." )
          elseif IsValid(victim) and !IsValid(killer) or !killer:IsTerror() then
            victim:PlayerMsg("Mirror Fate: ", Color(250,250,250) ,"Your killer is already dead!")
          end
        end
      end )
  end
  
  hook.Add( "DoPlayerDeath" , "MirrorfateKillhim" , KillTheKillerMirrorfate )
  hook.Add("PlayerDeath", "ResetMirrorfate", function(victim, inflictor, attacker)
      if victim.DyeOnFate == true then
        victim.DyeOnFate = false
      end
    end)
	
  hook.Add("TTTPrepareRound","RemoveMirrorFatekill", function()
      timer.Remove("BurnInHellMirrorfate")
      for key,ply in pairs(player.GetAll()) do
        timer.Remove("MirrorFatekill" .. ply:EntIndex())
        timer.Remove("BurnInHellMirrorfate" .. ply:EntIndex())
        ply.fatemode = 1
        ply.fatetime = 50
        ply.DyeOnFate = false
      end
  end)
  
end