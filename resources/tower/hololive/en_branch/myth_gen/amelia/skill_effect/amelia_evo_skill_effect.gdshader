shader_type canvas_item;
render_mode blend_add;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;

const float R        = 0.38;
const float UV_SCALE = 1.4; // matches BURST_PAD in .gd — lets burst reach R+0.28 within ±0.7

// ── SDF helpers ─────────────────────────────────────────────
float sdCircle(vec2 p, float r) {
	return length(p) - r;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// 4-point star — used for both stars and (rotated 45°) diamonds
float sdStar4(vec2 p, float r) {
	float s = 0.38;
	p = abs(p);
	if (p.y > p.x) p = p.yx;
	p.x -= r;
	p.y += s * r;
	float a = dot(p, vec2(s, -1.0));
	float b = dot(p, vec2(1.0,  s));
	return (max(a, b) < 0.0) ? -min(length(p - vec2(s, -1.0) * a),
	                                 length(p - vec2(1.0, s) * b))
	                          : length(max(vec2(a, b), 0.0));
}

// ── Easing ──────────────────────────────────────────────────
float easeOutElastic(float t) {
	if (t <= 0.0) return 0.0;
	if (t >= 1.0) return 1.0;
	return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * (TAU / 3.0)) + 1.0;
}

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float easeOut4(float t) { return 1.0 - pow(1.0 - t, 4.0); }

// ── Main ────────────────────────────────────────────────────
void fragment() {
	vec2  uv    = (UV - 0.5) * UV_SCALE / max(scale_p, 0.01);
	float dist  = length(uv);
	float angle = atan(uv.y, uv.x);

	vec3  col   = vec3(0.0);
	float alpha = 0.0;

	float fade     = progress < 0.78 ? 1.0 : 1.0 - (progress - 0.78) / 0.22;
	float handFade = progress < 0.72 ? 1.0 : 1.0 - (progress - 0.72) / 0.28;

	// ── 1. Ice-blue outer ring ───────────────────────────────
	float outerD = abs(dist - R);
	float outerA = smoothstep(0.022, 0.0, outerD) * fade;
	col   += vec3(0.63, 0.85, 1.0) * outerA * 3.0;
	alpha  = max(alpha, outerA);

	// ── 2. Pink inner ring ───────────────────────────────────
	float innerD = abs(dist - R * 0.93);
	float innerA = smoothstep(0.010, 0.0, innerD) * fade * 0.55;
	col   += vec3(1.0, 0.70, 0.85) * innerA * 2.0;
	alpha  = max(alpha, innerA * 0.4);

	// ── 3. Glass face (subtle ice tint) ─────────────────────
	float faceA = smoothstep(0.0, 0.015, R * 0.93 - dist) * fade * 0.08;
	col   += vec3(0.88, 0.96, 1.0) * faceA;
	alpha  = max(alpha, faceA * 0.5);

	// ── 4. Glass highlight arc (upper arc, precomputed angle) ─
	float arcD = abs(dist - (R - 0.04));
	float inArc = step(-PI * 0.75, angle) * step(angle, -PI * 0.15);
	float arcA  = smoothstep(0.008, 0.0, arcD) * inArc * fade * 0.22;
	col   += vec3(1.0, 1.0, 1.0) * arcA;
	alpha  = max(alpha, arcA * 0.5);

	// ── 5. Frost inner ring (pulsing) ────────────────────────
	float frostPulse = sin(progress * TAU * 5.0) * 0.5 + 0.5;
	float frostD = abs(dist - R * 0.55);
	float frostA = smoothstep(0.008, 0.0, frostD) * fade * 0.20 * frostPulse;
	col   += vec3(0.78, 0.93, 1.0) * frostA;
	alpha  = max(alpha, frostA * 0.5);

	// ── 6. 12 tick marks ─────────────────────────────────────
	for (int i = 0; i < 12; i++) {
		float tAngle = float(i) / 12.0 * TAU - PI * 0.5;
		vec2  tDir   = vec2(cos(tAngle), sin(tAngle));
		bool  isMain = (i % 3) == 0;

		if (isMain) {
			// Diamond shape: sdStar4 rotated 45° looks like ◇
			vec2  lUV = uv - tDir * (R - 0.04);
			float sa  = -tAngle + PI * 0.25; // 45° extra = diamond orientation
			vec2  rUV = vec2(lUV.x * cos(sa) - lUV.y * sin(sa),
			                 lUV.x * sin(sa) + lUV.y * cos(sa));
			float diaD = sdStar4(rUV, 0.018);
			float diaA = smoothstep(0.005, -0.003, diaD) * fade;
			col   += vec3(0.63, 0.85, 1.0) * diaA * 3.5;
			alpha  = max(alpha, diaA);
			// Pink inner dot accent
			float dotD = sdCircle(lUV, 0.006);
			float dotA = smoothstep(0.003, -0.001, dotD) * fade * 0.8;
			col   += vec3(1.0, 0.70, 0.85) * dotA * 2.0;
			alpha  = max(alpha, dotA);
		} else {
			// Thin ice-blue tick line
			vec2  tInner = tDir * (R - 0.050);
			vec2  tOuter = tDir * (R - 0.018);
			float tickD  = sdSegment(uv, tInner, tOuter);
			float tickA  = smoothstep(0.006, 0.001, tickD) * fade * 0.50;
			col   += vec3(0.50, 0.78, 1.0) * tickA * 2.0;
			alpha  = max(alpha, tickA);
		}
	}

	// ── 7. Hour hand (ice-blue) ──────────────────────────────
	float hAngle = progress * TAU * 4.0 - PI * 0.5;
	vec2  hEnd   = vec2(cos(hAngle), sin(hAngle)) * R * 0.52;
	vec2  hTail  = vec2(cos(hAngle + PI), sin(hAngle + PI)) * R * 0.12;
	float hDist  = sdSegment(uv, hTail, hEnd);
	float hA     = smoothstep(0.016, 0.004, hDist) * handFade;
	col   += vec3(0.63, 0.85, 1.0) * hA * 3.0;
	alpha  = max(alpha, hA);

	// ── 8. Minute hand (pink) ────────────────────────────────
	float mAngle = progress * TAU * 10.0 - PI * 0.5;
	vec2  mEnd   = vec2(cos(mAngle), sin(mAngle)) * R * 0.76;
	vec2  mTail  = vec2(cos(mAngle + PI), sin(mAngle + PI)) * R * 0.09;
	float mDist  = sdSegment(uv, mTail, mEnd);
	float mA     = smoothstep(0.011, 0.002, mDist) * handFade * 0.9;
	col   += vec3(1.0, 0.70, 0.85) * mA * 2.5;
	alpha  = max(alpha, mA);

	// ── 9. Crystal center gem (white → ice-blue → pink) ──────
	float gemD = dist;
	float gemA = smoothstep(0.038, 0.0, gemD) * handFade;
	float gemT = gemD / 0.038;
	vec3  gemC = mix(vec3(1.0), mix(vec3(0.78, 0.93, 1.0), vec3(1.0, 0.70, 0.85), gemT * 2.0), gemT);
	col   += gemC * gemA * 4.0;
	alpha  = max(alpha, gemA);

	// ── 10. Orbiting crystal diamonds (sdStar4 at 45°) ───────
	for (int i = 0; i < 8; i++) {
		float baseA  = float(i) / 8.0 * TAU;
		float spin   = progress * TAU * 3.5;
		float orbitR = R + 0.065;
		vec2  sPos   = vec2(cos(baseA + spin), sin(baseA + spin)) * orbitR;
		float pulse  = sin(progress * TAU * 4.0 + float(i) * 1.1) * 0.5 + 0.5;
		float sz     = mix(0.008, 0.020, pulse);
		// Rotate 45° for diamond look
		vec2  lUV2   = uv - sPos;
		float sa2    = PI * 0.25;
		vec2  rUV2   = vec2(lUV2.x * cos(sa2) - lUV2.y * sin(sa2),
		                    lUV2.x * sin(sa2) + lUV2.y * cos(sa2));
		float diaD   = sdStar4(rUV2, sz);
		float diaA   = smoothstep(0.004, -0.003, diaD) * pulse * fade;
		vec3  diaC   = ((i % 2) == 0) ? vec3(0.63, 0.85, 1.0) : vec3(1.0, 0.70, 0.85);
		col   += diaC * diaA * 3.5;
		alpha  = max(alpha, diaA * 0.9);
	}

	// ── 11. Frost center bloom ───────────────────────────────
	float bloom  = max(0.0, 1.0 - dist / 0.16);
	float bloomA = bloom * bloom * max(0.0, sin(progress * PI)) * 0.40;
	col   += vec3(0.86, 0.96, 1.0) * bloomA;
	alpha  = max(alpha, bloomA * 0.35);

	// ── 12. Crystal burst ────────────────────────────────────
	if (progress > 0.72) {
		float bt    = (progress - 0.72) / 0.28;
		float bFade = 1.0 - bt;

		// 3 expanding rings (alternating ice-blue / pink)
		// Max safe UV radius = UV_SCALE * 0.5 - ring_width = 0.686; so bR max ≤ 0.66
		float bR0 = mix(R, R + 0.18, easeOut3(bt));
		float bR1 = mix(R, R + 0.22, easeOut3(bt));
		float bR2 = mix(R, R + 0.26, easeOut3(bt));

		float k0A = smoothstep(0.014, 0.0, abs(dist - bR0)) * bFade * 0.55;
		col   += vec3(0.63, 0.85, 1.0) * k0A * 2.0;
		alpha  = max(alpha, k0A);

		float k1A = smoothstep(0.014, 0.0, abs(dist - bR1)) * bFade * 0.30;
		col   += vec3(1.0, 0.70, 0.85) * k1A * 2.0;
		alpha  = max(alpha, k1A);

		float k2A = smoothstep(0.014, 0.0, abs(dist - bR2)) * bFade * 0.15;
		col   += vec3(0.63, 0.85, 1.0) * k2A * 2.0;
		alpha  = max(alpha, k2A);

		// 16 diamond shards fly outward
		for (int i = 0; i < 16; i++) {
			float bAngle = float(i) / 16.0 * TAU;
			float bR     = mix(R, R + 0.28, easeOut4(bt));
			vec2  bPos   = vec2(cos(bAngle), sin(bAngle)) * bR;
			float sz     = mix(0.016, 0.005, bt);

			vec2  bLUV   = uv - bPos;
			float bsa    = PI * 0.25;
			vec2  bRUV   = vec2(bLUV.x * cos(bsa) - bLUV.y * sin(bsa),
			                    bLUV.x * sin(bsa) + bLUV.y * cos(bsa));
			float bDiaD  = sdStar4(bRUV, sz);
			float bA     = smoothstep(0.004, -0.003, bDiaD) * bFade * 0.85;

			vec3 bCol = vec3(0.63, 0.85, 1.0); // initialized
			if ((i % 3) == 1) bCol = vec3(1.0, 0.70, 0.85);
			if ((i % 3) == 2) bCol = vec3(0.90, 0.97, 1.0);

			col   += bCol * bA * 3.0;
			alpha  = max(alpha, bA);
		}
	}

	COLOR = vec4(col, alpha);
}
