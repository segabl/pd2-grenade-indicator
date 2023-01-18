local ICON_SIZE = 32

function ProjectileBase:_check_create_marker()
	if not self._range or not self._damage or self._damage < 1 then
		return
	end

	local tweak_entry = tweak_data.blackmarket.projectiles[self._tweak_projectile_entry or "frag"]
	if not tweak_entry or not tweak_entry.throwable then
		return
	end

	local hud = managers.hud and managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	if not hud then
		return
	end

	self._ui_marker = hud.panel:bitmap({
		color = tweak_data.hud.detected_color,
		blend_mode = "add",
		texture = "guis/textures/pd2/crimenet_challenge"
	})
	self._marker_h_ratio = self._ui_marker:texture_height() / self._ui_marker:texture_width()
end

function ProjectileBase:_update_marker(t, dt)
	local ws = managers.hud._workspace
	local cam = managers.viewport:get_current_camera()
	local player = managers.player:local_player()
	if not cam or not alive(player) then
		return
	end

	local dis = mvector3.distance(player:position(), self._unit:position())
	local size_scale = math.map_range_clamped(dis, self._range, self._range * 3, 1, 0.5)
	local alpha_scale = math.map_range_clamped(dis, self._range, self._range * 3, 1, 0)

	self._ui_marker:set_size(ICON_SIZE * size_scale, ICON_SIZE * size_scale * self._marker_h_ratio)

	local screen_pos = ws:world_to_screen(cam, self._unit:position())
	local x = math.clamp(screen_pos.x, 128, self._ui_marker:parent():w() - 128) - self._ui_marker:w() * 0.5
	local y = math.clamp(screen_pos.y, 128, self._ui_marker:parent():h() - 128) - self._ui_marker:h() * 0.75

	self._ui_marker:set_position(x, y)

	self._ui_marker:set_alpha(math.map_range(math.sin(t * 1000), -1, 1, 0.1, 1) * alpha_scale)
end

function ProjectileBase:_remove_marker()
	if alive(self._ui_marker) then
		self._ui_marker:parent():remove(self._ui_marker)
		self._ui_marker = nil
	end
end

Hooks:PostHook(GrenadeBase, "init", "init_marker", ProjectileBase._check_create_marker)

Hooks:PreHook(ProjectileBase, "destroy", "destroy_marker", ProjectileBase._remove_marker)

Hooks:PostHook(ProjectileBase, "update", "update_marker", function (self, unit, t, dt)
	if not alive(self._ui_marker) then
		return
	end

	if self._detonated then
		self:_remove_marker()
		return
	end

	self:_update_marker(t, dt)
end)
