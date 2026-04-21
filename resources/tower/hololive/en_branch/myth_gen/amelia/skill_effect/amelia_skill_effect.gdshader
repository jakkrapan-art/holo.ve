shader_type canvas_item;
render_mode blend_add;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;

const float R        = 0.38;
const float UV_SCALE = 1.4; // matches BURST_PAD in .gd — lets burst reach R+0.26 within ±0.7

// ── SDF helpers ─────────────────────────────────────────────
float sdCircle(vec2 p, float r) {
	return length(p) - r;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

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

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

// ── Main ────────────────────────────────────────────────────
void fragment() {
	vec2 uv   = (UV - 0.5) * UV_SCALE / max(scale_p, 0.01);
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	vec3  col   = vec3(0.0);
	float alpha = 0.0;

	float fade     = progress < 0.78 ? 1.0 : 1.0 - (progress - 0.78) / 0.22;
	float handFade = progress < 0.72 ? 1.0 : 1.0 - (progress - 0.72) / 0.28;

	// ── 1. Gold outer bezel (thick, with slight angle gradient) ──
	float bezelD  = abs(dist - R);
	float bezelA  = smoothstep(0.038, 0.0, bezelD) * fade;
	float bezelG  = sin(angle + PI * 0.5) * 0.25 + 0.75; // top brighter
	col   += vec3(1.0, 0.87, 0.0) * bezelA * 3.5 * bezelG;
	alpha  = max(alpha, bezelA);

	// ── 2. Bezel inner edge (thin dark line for depth) ──
	float edgeD = abs(dist - (R - 0.038));
	float edgeA = smoothstep(0.006, 0.0, edgeD) * fade * 0.5;
	col   += vec3(1.0, 0.80, 0.0) * edgeA;
	alpha  = max(alpha, edgeA * 0.4);

	// ── 3. Clock face fill (cream, visible) ──────────────────
	float faceA = smoothstep(0.0, 0.015, (R - 0.038) - dist) * fade * 0.22;
	col   += vec3(1.0, 0.97, 0.88) * faceA;
	alpha  = max(alpha, faceA * 0.7);

	// ── 4. 12 tick marks ─────────────────────────────────────
	for (int i = 0; i < 12; i++) {
		float tAngle = float(i) / 12.0 * TAU - PI * 0.5;
		vec2  tDir   = vec2(cos(tAngle), sin(tAngle));
		bool  isMain = (i % 3) == 0;

		float outerR = R - 0.042;
		float innerR = outerR - (isMain ? 0.075 : 0.042);

		// Tick line
		float tickD = sdSegment(uv, tDir * innerR, tDir * outerR);
		float tickW = isMain ? 0.010 : 0.006;
		float tickA = smoothstep(tickW, 0.001, tickD) * fade * (isMain ? 1.0 : 0.65);
		col   += (isMain ? vec3(1.0, 0.85, 0.0) : vec3(1.0, 0.80, 0.88)) * tickA * 2.5;
		alpha  = max(alpha, tickA);

		// 4-point gold star at main positions
		if (isMain) {
			vec2  lUV  = uv - tDir * (innerR - 0.008);
			float sa   = -tAngle;
			vec2  rUV  = vec2(lUV.x * cos(sa) - lUV.y * sin(sa),
			                  lUV.x * sin(sa) + lUV.y * cos(sa));
			float starD = sdStar4(rUV, 0.020);
			float starA = smoothstep(0.005, -0.003, starD) * fade;
			col   += vec3(1.0, 0.84, 0.0) * starA * 4.5;
			alpha  = max(alpha, starA);
		}
	}

	// ── 5. Hour hand (gold → pink, thicker) ──────────────────
	float hAngle = progress * TAU * 4.0 - PI * 0.5;
	vec2  hEnd   = vec2(cos(hAngle), sin(hAngle)) * (R - 0.042) * 0.58;
	vec2  hTail  = vec2(cos(hAngle + PI), sin(hAngle + PI)) * (R - 0.042) * 0.14;
	float hDist  = sdSegment(uv, hTail, hEnd);
	float hA     = smoothstep(0.018, 0.004, hDist) * handFade;
	float handT  = clamp(dot(uv - hTail, normalize(hEnd - hTail)) / length(hEnd - hTail), 0.0, 1.0);
	vec3  hCol   = mix(vec3(1.0, 0.84, 0.0), vec3(1.0, 0.62, 0.80), handT);
	col   += hCol * hA * 4.0;
	alpha  = max(alpha, hA);

	// ── 6. Minute hand (pink, long thin) ─────────────────────
	float mAngle = progress * TAU * 10.0 - PI * 0.5;
	vec2  mEnd   = vec2(cos(mAngle), sin(mAngle)) * (R - 0.042) * 0.82;
	vec2  mTail  = vec2(cos(mAngle + PI), sin(mAngle + PI)) * (R - 0.042) * 0.10;
	float mDist  = sdSegment(uv, mTail, mEnd);
	float mA     = smoothstep(0.011, 0.002, mDist) * handFade * 0.9;
	col   += vec3(1.0, 0.70, 0.85) * mA * 2.8;
	alpha  = max(alpha, mA);

	// ── 7. Center pivot cap ───────────────────────────────────
	float capA = smoothstep(0.020, 0.0, dist) * handFade;
	float capT = dist / 0.020;
	vec3  capC = mix(vec3(1.0), mix(vec3(1.0, 0.84, 0.0), vec3(1.0, 0.62, 0.80), capT * 2.0), capT);
	col   += capC * capA * 5.0;
	alpha  = max(alpha, capA);

	// ── 8. Soft pink center bloom ─────────────────────────────
	float bloom  = max(0.0, 1.0 - dist / 0.12);
	float bloomA = bloom * bloom * max(0.0, sin(progress * PI)) * 0.45;
	col   += vec3(1.0, 0.92, 0.96) * bloomA;
	alpha  = max(alpha, bloomA * 0.35);

	// ── 9. Cherry blossom burst ───────────────────────────────
	if (progress > 0.72) {
		float bt     = (progress - 0.72) / 0.28;
		float bFade  = 1.0 - bt;
		float burstR = mix(R, R + 0.20, easeOut3(bt));

		// Expanding pink ring
		float bRingD = abs(dist - burstR);
		float bRingA = smoothstep(0.018, 0.0, bRingD) * bFade * 0.5;
		col   += vec3(1.0, 0.70, 0.85) * bRingA * 2.0;
		alpha  = max(alpha, bRingA);

		// Stars and dots scatter
		for (int i = 0; i < 16; i++) {
			float bAngle = float(i) / 16.0 * TAU;
			float bR     = mix(R, R + 0.18, easeOut3(bt));
			vec2  bPos   = vec2(cos(bAngle), sin(bAngle)) * bR;

			if ((i % 4) == 0) {
				float sz    = mix(0.018, 0.005, bt);
				float bStarD = sdStar4(uv - bPos, sz);
				float bA    = smoothstep(0.004, -0.003, bStarD) * bFade * 0.9;
				col   += vec3(1.0, 0.84, 0.0) * bA * 3.0;
				alpha  = max(alpha, bA);
			} else {
				float bDotD = sdCircle(uv - bPos, 0.008);
				float bA    = smoothstep(0.004, -0.003, bDotD) * bFade * 0.6;
				col   += vec3(1.0, 0.70, 0.85) * bA * 2.0;
				alpha  = max(alpha, bA);
			}
		}
	}

	COLOR = vec4(col, alpha);
}
