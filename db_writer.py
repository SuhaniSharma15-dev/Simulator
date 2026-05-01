"""
================================================================================
  EduMetrics Simulator — db_writer2.py  v4

  Designed around a realistic 2-semester simulation of 4 concurrent classes
  (40 students each).  Every behaviour rule is modelled as a concrete mechanism,
  not just noise.

  ── DESIGN PRINCIPLES (from spec) ────────────────────────────────────────────

  1.  FIRST-YEAR ADJUSTMENT CURVE
      Y1 students in sem 1 carry an "adjustment penalty" that varies per student.
      Some struggle (penalty −8 to −18 on score/quality), some adapt fine (+2),
      some hit the ground running if they have prior knowledge (+5 to +12).
      In sem 2 the penalty fully resolves — so sem2 may be better OR worse
      depending on whether that student's sem1 was already boosted.

  2.  MIDTERM vs ENDTERM BIAS
      Each student has a personal exam_bias drawn from their trait_seed.
      Positive = endterm specialist (peaks late).  Negative = midterm specialist.
      Applied as ±0 to ±12 pts on the respective exam type.

  3.  MOST PEOPLE AROUND 80-85% ATTENDANCE
      Archetype bases pulled down to realistic ranges.  Most archetypes centre
      79-88%.  Only high_performer sits near 90.  Noise sigma reduced to 3.5.

  4.  WEEK-TO-WEEK FLUCTUATION: most ±10-20%, volatiles go higher
      Each student has a volatility score (low/medium/high) from trait_seed.
      Low-vol students: weekly noise sigma 3-5.
      High-vol students: sigma 10-14, plus rare "spike weeks" (random.random()
      < 0.08) where a single week can swing ±20-28 pts.

  5.  SKILL COMPOUNDING
      Students carry a momentum float that updates each semester based on their
      previous exam result relative to their archetype baseline.  Good sem → +3
      to +6 pts added to next sem base.  Bad sem → -2 to -4.  Stored in
      students table as momentum FLOAT.

  6.  BURNOUT MECHANICS (lag pattern)
      Burnout students: quality and library degrade first (weeks 4-8 of burnout
      sem), attendance follows 3-4 weeks later, grades follow at endterm.
      Contrast with crisis_student who drops everything at once.

  7.  PRIORITY-ABSENT STUDENTS
      A new archetype priority_absent. These students hold ~75% attendance
      consistently with low variance — no sudden drops, no spikes.
      They have other commitments (part-time work, sports, family).

  8.  HARD WORK != GREAT MARKS
      Two orthogonal traits: effort_score (how hard they work) and
      efficiency (how well effort converts to marks).  A student can be
      high-effort/low-efficiency (studies hard, still gets 55%).  Both derived
      from trait_seed.

  9.  SEMESTER-TO-SEMESTER PERSONAL DRIFT
      Each student has a sem_drift drawn once (+/-3 pts) that shifts their base
      slightly each semester.  No two students drift the same way.

  10. CLASS AND BATCH PERSONALITY
      Each class has a class_seed (stored in classes table) that determines
      class-level personality offsets: some classes are naturally higher
      attendance, some have wider score variance, some submit early.

  11. EXAM CRUNCH: everyone studies more pre-exam
      Weeks 6-7 (pre-midterm) and weeks 16-17 (pre-endterm): library visits
      surge, submission latency drops, quiz attempt rate rises.
      The magnitude scales with the student's effort_score.

  12. PEOPLE CHANGE A BIT SEM-TO-SEM
      Momentum + drift + sem-boundary resample: each student's weekly base
      shifts slightly between semesters.

  ── STUDENT ATTRIBUTES (required in students table) ──────────────────────────
    trait_seed    INT          deterministic RNG seed for all personal offsets
    dramatic_arc  VARCHAR(20)  'phoenix' / 'collapse' / 'shooting_star' / ''
    arc_semester  TINYINT      semester where arc activates
    momentum      FLOAT        running skill momentum, updated after each sem

  ── CLASS ATTRIBUTES (required in classes table) ──────────────────────────────
    class_seed    INT          class personality seed

  ── PUBLIC API ────────────────────────────────────────────────────────────────
    advance_week(seed=None)     -> dict
    rollback_to_week(target)    -> dict
    get_db_status()             -> dict
================================================================================
"""

import sys, os, random
from datetime import date, timedelta, datetime

sys.path.insert(0, os.path.dirname(__file__))
from connection import query, get_conn

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
WEEKS_PER_SEM      = 18
TOTAL_WEEKS        = WEEKS_PER_SEM * 2
MIDTERM_WEEK       = 8
ENDTERM_WEEK       = 18
EXAM_WEEKS         = {MIDTERM_WEEK, ENDTERM_WEEK}
RESULT_DELAY_WEEKS = 2
PRE_MIDTERM_CRUNCH = {6, 7}
PRE_ENDTERM_CRUNCH = {16, 17}
CRUNCH_WEEKS       = PRE_MIDTERM_CRUNCH | PRE_ENDTERM_CRUNCH

# ── ARCHETYPE PROFILES ────────────────────────────────────────────────────────
ARCHETYPES = {
    "high_performer": {
        "attend": 91, "sub": 94, "lat": -48, "qual": 84,
        "plag":  2,   "qa": 92, "qs": 83,   "lib": 3.4,
        "sem_score_delta": -0.5, "sem_attend_delta": -0.4,
    },
    "consistent_avg": {
        "attend": 85, "sub": 80, "lat": -18, "qual": 65,
        "plag":  8,   "qa": 72, "qs": 62,   "lib": 1.7,
        "sem_score_delta": -0.3, "sem_attend_delta": -0.6,
    },
    "late_bloomer": {
        "attend": 76, "sub": 52, "lat":  -4, "qual": 49,
        "plag": 13,   "qa": 44, "qs": 42,   "lib": 0.7,
        "sem_score_delta": +4.5, "sem_attend_delta": +1.8,
        "midterm_penalty": -10,
    },
    "slow_fader": {
        "attend": 88, "sub": 78, "lat": -20, "qual": 68,
        "plag":  9,   "qa": 70, "qs": 63,   "lib": 1.5,
        "sem_score_delta": -4.0, "sem_attend_delta": -2.2,
    },
    "crammer": {
        "attend": 78, "sub": 50, "lat":  -2, "qual": 56,
        "plag": 19,   "qa": 35, "qs": 49,   "lib": 0.3,
        "sem_score_delta": -0.7, "sem_attend_delta": -0.5,
    },
    "crisis_student": {
        "attend": 85, "sub": 78, "lat": -20, "qual": 68,
        "plag":  7,   "qa": 72, "qs": 63,   "lib": 1.7,
        "sem_score_delta": -0.3, "sem_attend_delta": -0.7,
        "crisis_score_drop": -36, "crisis_attend_drop": -32, "crisis_sub_drop": -38,
    },
    "silent_disengager": {
        "attend": 79, "sub": 73, "lat": -12, "qual": 60,
        "plag": 15,   "qa":  8, "qs": 42,   "lib": 0.1,
        "sem_score_delta": -0.9, "sem_attend_delta": -0.7,
    },
    "burnout_risk": {
        "attend": 90, "sub": 89, "lat": -42, "qual": 80,
        "plag":  4,   "qa": 86, "qs": 77,   "lib": 2.6,
        "sem_score_delta": -7.0, "sem_attend_delta": -4.5,
        "burnout_sem": 2,
    },
    "social_learner": {
        "attend": 87, "sub": 68, "lat":  -7, "qual": 58,
        "plag": 17,   "qa": 52, "qs": 51,   "lib": 0.25,
        "sem_score_delta": -0.4, "sem_attend_delta": -0.2,
    },
    "priority_absent": {
        "attend": 75, "sub": 71, "lat":  -8, "qual": 62,
        "plag": 11,   "qa": 58, "qs": 55,   "lib": 0.6,
        "sem_score_delta": -0.4, "sem_attend_delta": -0.1,
    },
}

CLS_MOD = {1: 1, 2: 2, 3: -1, 4: -2, 5: -4, 6: -3, 7: -6, 8: -7}


# ── HELPERS ───────────────────────────────────────────────────────────────────
def _clamp(v, lo, hi):
    return max(lo, min(hi, v))

def _noisy(v, sigma, lo=0.0, hi=100.0):
    return _clamp(v + random.gauss(0, sigma), lo, hi)

def _arc(archetype_str):
    return ARCHETYPES.get(archetype_str, ARCHETYPES["consistent_avg"])

def _score_to_grade(pct):
    if pct >= 90: return "O"
    if pct >= 80: return "A+"
    if pct >= 70: return "A"
    if pct >= 60: return "B+"
    if pct >= 50: return "B"
    if pct >= 40: return "C"
    return "F"


# ── TRAIT DERIVATION ─────────────────────────────────────────────────────────
def _get_traits(trait_seed):
    """
    Derive all per-student personal traits from a single seed.
    Using an isolated random.Random so the global seed is never disturbed.
    """
    rng = random.Random(trait_seed)
    attend_offset = rng.gauss(0, 8)
    qual_offset   = rng.gauss(0, 8)
    qs_offset     = rng.gauss(0, 7)
    qa_offset     = rng.gauss(0, 7)
    lib_scale     = _clamp(rng.gauss(1.0, 0.20), 0.35, 1.9)
    sub_offset    = rng.gauss(0, 6)

    vol_roll   = rng.random()
    volatility = "low" if vol_roll < 0.25 else ("high" if vol_roll > 0.80 else "medium")

    exam_bias    = rng.uniform(-12, 12)
    effort_score = _clamp(rng.gauss(55, 18), 10, 100)
    efficiency   = _clamp(rng.gauss(55, 18), 10, 100)
    sem_drift    = rng.gauss(0, 3)
    adj_curve    = rng.gauss(-3, 10)

    return {
        "attend_offset": attend_offset,
        "qual_offset":   qual_offset,
        "qs_offset":     qs_offset,
        "qa_offset":     qa_offset,
        "lib_scale":     lib_scale,
        "sub_offset":    sub_offset,
        "volatility":    volatility,
        "exam_bias":     exam_bias,
        "effort_score":  effort_score,
        "efficiency":    efficiency,
        "sem_drift":     sem_drift,
        "adj_curve":     adj_curve,
    }


def _weekly_sigma(volatility, base_sigma=3.5):
    if volatility == "low":
        return base_sigma * 0.7, False
    if volatility == "medium":
        return base_sigma, False
    is_spike = random.random() < 0.08
    return (base_sigma * 3.0 if is_spike else base_sigma * 1.8), is_spike


def _effort_to_quality(effort, efficiency, base_qual):
    """
    Hard work does not guarantee great marks.
    effort_score  : motivation / hours
    efficiency    : skill / technique / prior knowledge
    Returns adjusted quality base.
    """
    converted = (effort / 100.0) * 0.35 + (efficiency / 100.0) * 0.65
    offset    = (converted - 0.55) * 30
    return base_qual + offset


# ── CLASS PERSONALITY ─────────────────────────────────────────────────────────
def _get_class_personality(class_seed):
    rng = random.Random(class_seed)
    return {
        "attend_bias":  rng.gauss(0, 4),
        "score_bias":   rng.gauss(0, 3),
        "sub_bias":     rng.gauss(0, 3),
        "latency_bias": rng.gauss(0, 8),
    }


# ── CRISIS PHASE ──────────────────────────────────────────────────────────────
def _crisis_phase(sem_week):
    if sem_week <= 4:  return 0.25 + (sem_week - 1) * 0.10
    if sem_week <= 10: return 1.0
    return max(0.35, 0.55 - (sem_week - 10) * 0.025)


# ── BURNOUT LAG ───────────────────────────────────────────────────────────────
def _burnout_factor(sem_week, trait="quality"):
    """
    Quality/lib/submission degrade from week 4.
    Attendance lags — starts degrading from week 7.
    Exam score shows full effect by endterm.
    """
    if trait == "quality":
        return _clamp((sem_week - 3) / 10.0, 0, 1.0) if sem_week >= 4 else 0.0
    if trait == "attend":
        return _clamp((sem_week - 6) / 10.0, 0, 0.7) if sem_week >= 7 else 0.0
    return 0.85  # exam


# ── DRAMATIC ARC ──────────────────────────────────────────────────────────────
def _arc_mod(stu, semester, sem_week, stat):
    arc, arc_sem = stu.get("dramatic_arc", ""), stu.get("arc_semester", 0)
    if not arc or not arc_sem:
        return 0
    if arc == "phoenix":
        if semester < arc_sem:
            return {"attend": -12, "score": -18, "sub": -16, "qa": -22, "qs": -15, "lib": -0.4}.get(stat, 0)
        return {"attend": +9, "score": +20, "sub": +14, "qa": +25, "qs": +18, "lib": +1.1}.get(stat, 0)
    if arc == "collapse":
        if semester < arc_sem: return 0
        depth = _clamp((sem_week or 8) / 8.0, 0.3, 1.0)
        return {"attend": -20, "score": -28, "sub": -25, "qa": -32, "qs": -22, "lib": -0.7}.get(stat, 0) * depth
    if arc == "shooting_star":
        if semester != arc_sem or not (4 <= (sem_week or 0) <= 14): return 0
        return {"attend": +7, "score": +16, "sub": +12, "qa": +18, "qs": +14, "lib": +1.3}.get(stat, 0)
    return 0


# ── FIRST-YEAR ADJUSTMENT ─────────────────────────────────────────────────────
def _y1_adj(stu, semester, year_of_study):
    """
    In Y1 sem 1: each student has an adj_curve (can be + or -).
    Positive: prior knowledge, breezes through.
    Negative: overwhelmed, struggles.
    In sem 2: resolves to 0 (adapted).
    This means sem2 can be better OR worse depending on which direction adj_curve was.
    """
    if year_of_study != 1:
        return 0
    odd_sem = stu.get("odd_sem", 1)
    if semester != odd_sem:
        return 0
    return _get_traits(stu["trait_seed"])["adj_curve"]


# ── WEEK MODIFIERS ────────────────────────────────────────────────────────────
def _week_mods(sem_week, semester, effort_score=55):
    m = {"attend": 0, "lat_add": 0.0, "lib_add": 0.0, "qa_boost": 0}
    en = effort_score / 100.0
    if sem_week in PRE_MIDTERM_CRUNCH:
        m["lib_add"] += 1.8 * en + 0.8
        m["lat_add"] += 5 * en
        m["attend"]  -= 2
        m["qa_boost"]+= 12 * en
    if sem_week == 9:
        m["attend"]  -= 3
    if sem_week in PRE_ENDTERM_CRUNCH:
        m["lib_add"] += 2.5 * en + 1.0
        m["lat_add"] += 7 * en
        m["qa_boost"]+= 15 * en
    if semester >= 5 and 9 <= sem_week <= 14:
        m["attend"]  -= 4
    return m


# ── DATE HELPERS ──────────────────────────────────────────────────────────────
def _sem_start(sim_year, semester):
    yr, month = (sim_year, 8) if semester % 2 == 1 else (sim_year + 1, 1)
    d = date(yr, month, 1)
    return d + timedelta(days=(7 - d.weekday()) % 7)

def _week_monday(sem_start_date, week_num):
    return sem_start_date + timedelta(weeks=week_num - 1)

def _global_to_sem_week(global_week):
    if global_week <= WEEKS_PER_SEM:
        return global_week, "odd"
    return global_week - WEEKS_PER_SEM, "even"


# ── DB READ HELPERS ───────────────────────────────────────────────────────────
def _fetch_all(cur, sql, params=()):
    cur.execute(sql, params)
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]

def _get_sim_state(cur):
    rows = _fetch_all(cur, "SELECT current_week, sim_year FROM sim_state WHERE id=1")
    if not rows: raise RuntimeError("sim_state empty.")
    return rows[0]

def _get_classes(cur):
    return _fetch_all(cur,
        "SELECT class_id, year_of_study, odd_sem, even_sem, "
        "COALESCE(class_seed, 1000) AS class_seed FROM classes")

def _get_students(cur, class_id):
    return _fetch_all(cur,
        """SELECT s.student_id, s.archetype,
                  COALESCE(s.crisis_sem,    0)   AS crisis_sem,
                  COALESCE(s.trait_seed,    0)   AS trait_seed,
                  COALESCE(s.dramatic_arc, '')   AS dramatic_arc,
                  COALESCE(s.arc_semester,  0)   AS arc_semester,
                  COALESCE(s.momentum,    0.0)   AS momentum,
                  COALESCE(de.dropout_semester,0) AS dropout_semester,
                  COALESCE(de.last_active_week,0) AS dropout_last_week
           FROM   students s
           LEFT JOIN dropout_events de ON s.student_id = de.student_id
           WHERE  s.class_id = %s""", (class_id,))

def _get_subjects_for_sem(cur, class_id, semester):
    return _fetch_all(cur,
        """SELECT s.subject_id FROM subjects s
           JOIN class_subjects cs ON s.subject_id = cs.subject_id
           WHERE cs.class_id=%s AND s.semester=%s""", (class_id, semester))

def _get_assignments_due(cur, class_id, semester, sem_week):
    return _fetch_all(cur,
        """SELECT assignment_id, subject_id, max_marks FROM assignment_definitions
           WHERE class_id=%s AND semester=%s AND due_week=%s""",
        (class_id, semester, sem_week))

def _get_active_load(cur, class_id, semester, sem_week):
    return _fetch_all(cur,
        """SELECT COUNT(*) AS n FROM assignment_definitions
           WHERE class_id=%s AND semester=%s AND due_week=%s""",
        (class_id, semester, sem_week))[0]["n"]

def _get_quizzes(cur, class_id, semester, sem_week):
    return _fetch_all(cur,
        """SELECT quiz_id, subject_id, max_marks FROM quiz_definitions
           WHERE class_id=%s AND semester=%s AND scheduled_week=%s""",
        (class_id, semester, sem_week))

def _get_exam_schedule(cur, class_id, semester, sem_week):
    return _fetch_all(cur,
        """SELECT schedule_id, subject_id, exam_type, max_marks FROM exam_schedule
           WHERE class_id=%s AND semester=%s AND scheduled_week=%s""",
        (class_id, semester, sem_week))

def _get_assignment_due_date(cur, assignment_id):
    rows = _fetch_all(cur,
        "SELECT due_week FROM assignment_definitions WHERE assignment_id=%s",
        (assignment_id,))
    return rows[0]["due_week"] if rows else None

def _week_exists(cur, class_id, semester, sem_week):
    return _fetch_all(cur,
        """SELECT COUNT(*) AS n FROM attendance
           WHERE class_id=%s AND semester=%s AND week=%s""",
        (class_id, semester, sem_week))[0]["n"] > 0

def _is_student_active(stu, semester, sem_week):
    dsem = stu["dropout_semester"]
    if dsem == 0: return True
    if semester < dsem: return True
    if semester == dsem and sem_week <= stu["dropout_last_week"]: return True
    return False


# ── SEM-START CACHE ───────────────────────────────────────────────────────────
_sem_start_cache = {}

def _sem_start_from_cache(class_id, semester):
    return _sem_start_cache[(class_id, semester)]

def _populate_sem_start_cache(cur, classes, sim_year):
    _sem_start_cache.clear()
    for cls in classes:
        for sem in (cls["odd_sem"], cls["even_sem"]):
            _sem_start_cache[(cls["class_id"], sem)] = _sem_start(sim_year, sem)


# ── ROW GENERATORS ────────────────────────────────────────────────────────────

def _build_attendance(students, subjects, class_id, semester, sem_week,
                      wdate, year_of_study, cls_p):
    rows    = []
    cls_mod = CLS_MOD.get(semester, 0)

    for stu in students:
        if not _is_student_active(stu, semester, sem_week): continue

        a          = _arc(stu["archetype"])
        tr         = _get_traits(stu["trait_seed"])
        ev         = _week_mods(sem_week, semester, tr["effort_score"])
        sem_offset = semester - 1
        in_crisis  = (stu["crisis_sem"] != 0 and stu["crisis_sem"] == semester)
        is_dropout = (stu["dropout_semester"] != 0 and stu["dropout_semester"] == semester)

        # priority_absent: tightly clamped, low variance, no modifiers
        if stu["archetype"] == "priority_absent":
            base = _clamp(a["attend"] + tr["attend_offset"] * 0.3, 68, 82)
            base = _noisy(base, 2.5, 60, 85)
            for subj in subjects:
                lec     = 3
                present = round(lec * base / 100)
                late    = 1 if present < lec and random.random() < 0.25 else 0
                absent  = max(0, lec - present - late)
                rows.append((stu["student_id"], class_id, subj["subject_id"],
                              semester, sem_week, str(wdate),
                              lec, present, absent, late,
                              round(present / lec * 100, 1)))
            continue

        base = (a["attend"]
                + tr["attend_offset"]
                + tr["sem_drift"]
                + cls_mod
                + cls_p["attend_bias"]
                + a.get("sem_attend_delta", 0) * sem_offset
                + ev["attend"])

        if stu["archetype"] == "crammer" and sem_week in CRUNCH_WEEKS:
            base += 9

        if in_crisis:
            base += a.get("crisis_attend_drop", 0) * _crisis_phase(sem_week)

        if stu["archetype"] == "burnout_risk":
            b_sem = a.get("burnout_sem", 2)
            if semester >= b_sem:
                base -= 14 * _burnout_factor(sem_week, "attend")

        if is_dropout:
            base -= 22

        base += _arc_mod(stu, semester, sem_week, "attend")
        base += stu.get("momentum", 0) * 0.15

        sigma, _ = _weekly_sigma(tr["volatility"])
        base     = _noisy(_clamp(base, 10, 100), sigma, 10, 100)

        for subj in subjects:
            lec     = 3
            s_att   = _clamp(base + random.gauss(0, 4), 0, 100)
            present = round(lec * s_att / 100)
            late    = 1 if present < lec and random.random() < 0.28 else 0
            absent  = max(0, lec - present - late)
            rows.append((stu["student_id"], class_id, subj["subject_id"],
                         semester, sem_week, str(wdate),
                         lec, present, absent, late,
                         round(present / lec * 100, 1)))
    return rows


def _build_assignment_submissions(cur, students, assignments, class_id,
                                   semester, sem_week, year_of_study, cls_p):
    if not assignments: return []
    active_load = _get_active_load(cur, class_id, semester, sem_week)
    rows        = []

    for stu in students:
        if not _is_student_active(stu, semester, sem_week): continue

        a          = _arc(stu["archetype"])
        tr         = _get_traits(stu["trait_seed"])
        ev         = _week_mods(sem_week, semester, tr["effort_score"])
        sem_offset = semester - 1
        in_crisis  = (stu["crisis_sem"] != 0 and stu["crisis_sem"] == semester)

        for asn in assignments:
            ws = (a["sub"] + tr["sub_offset"] + cls_p["sub_bias"]
                  + a.get("sem_score_delta", 0) * sem_offset * 0.3)
            wl = a["lat"] + ev["lat_add"] + cls_p["latency_bias"]

            base_qual = _effort_to_quality(
                tr["effort_score"], tr["efficiency"],
                a["qual"] + tr["qual_offset"] + cls_p["score_bias"])

            if stu["archetype"] == "slow_fader":
                ws -= sem_offset * 2.5; wl += sem_offset * 4; base_qual -= sem_offset * 2.5

            if stu["archetype"] == "late_bloomer":
                ws += sem_offset * 3.5; wl -= sem_offset * 3.5; base_qual += sem_offset * 4.5

            if stu["archetype"] == "burnout_risk":
                b_sem = a.get("burnout_sem", 2)
                if semester >= b_sem:
                    bf = _burnout_factor(sem_week, "quality")
                    ws -= 20 * bf; base_qual -= 18 * bf; wl += 15 * bf

            if in_crisis:
                phase = _crisis_phase(sem_week)
                ws += a.get("crisis_sub_drop", 0) * phase
                base_qual -= 15 * phase

            if stu["archetype"] == "crammer":
                wl += 18
                if sem_week in CRUNCH_WEEKS: ws += 12; wl -= 10

            if active_load >= 4:
                wl += 9

            if year_of_study == 1:
                base_qual += _y1_adj(stu, semester, year_of_study) * 0.6

            base_qual += _arc_mod(stu, semester, sem_week, "sub")
            base_qual += stu.get("momentum", 0) * 0.25

            submitted = random.random() < _clamp(ws, 5, 99) / 100
            if not submitted:
                rows.append((asn["assignment_id"], stu["student_id"], class_id,
                             "missing", None, None, None, None, 0.0))
                continue

            sigma, _ = _weekly_sigma(tr["volatility"], base_sigma=8)
            quality  = _noisy(base_qual, sigma, 12, 100)
            marks    = round(asn["max_marks"] * quality / 100)
            q_pct    = round(marks / asn["max_marks"] * 100, 1)
            latency  = _noisy(wl, 11, -120, 48)
            plag     = round(_noisy(a["plag"], 7, 0, 75), 1) if random.random() < 0.14 else 0.0
            is_late  = latency > 0

            sub_dt = None
            due_wk = _get_assignment_due_date(cur, asn["assignment_id"])
            if due_wk:
                sem_start = _sem_start_from_cache(class_id, semester)
                sub_dt    = str(_week_monday(sem_start, due_wk) + timedelta(hours=latency))

            rows.append((asn["assignment_id"], stu["student_id"], class_id,
                         "late" if is_late else "on_time",
                         sub_dt, round(latency, 1), marks, q_pct, plag))
    return rows


def _build_quiz_submissions(students, quizzes, class_id, semester, sem_week,
                             year_of_study, cls_p):
    if not quizzes: return []
    rows = []

    for stu in students:
        if not _is_student_active(stu, semester, sem_week): continue

        a          = _arc(stu["archetype"])
        tr         = _get_traits(stu["trait_seed"])
        ev         = _week_mods(sem_week, semester, tr["effort_score"])
        sem_offset = semester - 1
        in_crisis  = (stu["crisis_sem"] != 0 and stu["crisis_sem"] == semester)

        for qz in quizzes:
            wqa = (a["qa"] + tr["qa_offset"] + ev["qa_boost"]
                   + cls_p["sub_bias"] * 0.4)
            wqs = _effort_to_quality(
                tr["effort_score"], tr["efficiency"],
                a["qs"] + tr["qs_offset"] + cls_p["score_bias"] * 0.5)

            if stu["archetype"] == "silent_disengager": wqa -= 62
            if stu["archetype"] == "slow_fader":
                wqa -= sem_offset * 4; wqs -= sem_offset * 2.5
            if stu["archetype"] == "burnout_risk":
                b_sem = a.get("burnout_sem", 2)
                if semester >= b_sem:
                    bf = _burnout_factor(sem_week, "quality")
                    wqa -= 22 * bf; wqs -= 18 * bf
            if in_crisis:
                ph = _crisis_phase(sem_week)
                wqa -= 48 * ph; wqs -= 28 * ph
            if stu["archetype"] == "late_bloomer":
                wqa += sem_offset * 7; wqs += sem_offset * 5
            if stu["archetype"] == "crammer" and sem_week in CRUNCH_WEEKS:
                wqa += 30; wqs += 8
            if year_of_study == 1:
                wqs += _y1_adj(stu, semester, year_of_study) * 0.5

            wqa += _arc_mod(stu, semester, sem_week, "qa")
            wqs += _arc_mod(stu, semester, sem_week, "qs")
            wqs += stu.get("momentum", 0) * 0.2

            attempted = random.random() < _clamp(wqa, 2, 99) / 100
            if not attempted:
                rows.append((qz["quiz_id"], stu["student_id"], class_id,
                             0, None, None, None))
                continue

            sigma, _ = _weekly_sigma(tr["volatility"], base_sigma=10)
            spct  = _noisy(wqs, sigma, 8, 100)
            marks = round(qz["max_marks"] * spct / 100)
            s_pct = round(marks / qz["max_marks"] * 100, 1)
            rows.append((qz["quiz_id"], stu["student_id"], class_id,
                         1, str(datetime.now().date()), marks, s_pct))
    return rows


def _build_library_visits(students, class_id, semester, sem_week, wdate,
                           year_of_study, cls_p):
    rows = []

    for stu in students:
        if not _is_student_active(stu, semester, sem_week): continue

        a          = _arc(stu["archetype"])
        tr         = _get_traits(stu["trait_seed"])
        ev         = _week_mods(sem_week, semester, tr["effort_score"])
        sem_offset = semester - 1
        in_crisis  = (stu["crisis_sem"] != 0 and stu["crisis_sem"] == semester)
        en         = tr["effort_score"] / 100.0

        wlib = a["lib"] * tr["lib_scale"] + ev["lib_add"] * en

        if stu["archetype"] == "silent_disengager": wlib *= 0.15
        if stu["archetype"] == "social_learner":    wlib *= 0.35
        if stu["archetype"] == "priority_absent":   wlib *= 0.5
        if stu["archetype"] == "burnout_risk":
            b_sem = a.get("burnout_sem", 2)
            if semester >= b_sem:
                wlib *= (1 - 0.85 * _burnout_factor(sem_week, "quality"))
        if in_crisis:
            wlib *= (1 - 0.88 * _crisis_phase(sem_week))
        if stu["archetype"] == "crammer" and sem_week in CRUNCH_WEEKS:
            wlib += 2.8 * en
        if stu["archetype"] == "late_bloomer":
            wlib += sem_offset * 0.28
        if year_of_study == 1:
            wlib += max(0, -_y1_adj(stu, semester, year_of_study)) * 0.06

        wlib += _arc_mod(stu, semester, sem_week, "lib")
        wlib += stu.get("momentum", 0) * 0.04
        wlib  = max(0, wlib)

        visits = max(0, round(random.gauss(wlib, 0.7)))
        rows.append((stu["student_id"], class_id, semester, sem_week, str(wdate), visits))
    return rows


def _build_exam_results(students, exams, class_id, semester, result_date,
                         year_of_study, cls_p):
    if not exams: return []
    cls_mod    = CLS_MOD.get(semester, 0)
    sem_offset = semester - 1
    rows       = []

    BASE_SCORES = {
        "high_performer":    {"midterm": 84, "endterm": 86},
        "consistent_avg":    {"midterm": 64, "endterm": 66},
        "late_bloomer":      {"midterm": 45, "endterm": 62},
        "slow_fader":        {"midterm": 73, "endterm": 53},
        "crammer":           {"midterm": 50, "endterm": 64},
        "crisis_student":    {"midterm": 65, "endterm": 45},
        "silent_disengager": {"midterm": 55, "endterm": 54},
        "burnout_risk":      {"midterm": 82, "endterm": 68},
        "social_learner":    {"midterm": 58, "endterm": 57},
        "priority_absent":   {"midterm": 60, "endterm": 59},
    }

    for stu in students:
        dsem = stu["dropout_semester"]
        if dsem != 0 and dsem <= semester:
            if dsem < semester: continue
            if stu["dropout_last_week"] < MIDTERM_WEEK: continue

        a         = _arc(stu["archetype"])
        tr        = _get_traits(stu["trait_seed"])
        in_crisis = (stu["crisis_sem"] != 0 and stu["crisis_sem"] == semester)

        for ex in exams:
            etype = ex["exam_type"]
            base  = BASE_SCORES.get(stu["archetype"], {"midterm": 62, "endterm": 62})[etype]

            # Class and batch
            base += cls_mod * 0.3 + cls_p["score_bias"] * 0.5

            # Effort x efficiency (partial effect on exams)
            base += _effort_to_quality(tr["effort_score"], tr["efficiency"], 0) * 0.5

            # Midterm vs endterm specialist
            bias_factor = -0.6 if etype == "midterm" else 0.6
            base += tr["exam_bias"] * bias_factor

            # Longitudinal
            base += a.get("sem_score_delta", 0) * sem_offset
            base += stu.get("momentum", 0) * 0.4
            base += tr["sem_drift"] * 0.5

            # Archetype-specific
            if stu["archetype"] == "late_bloomer":
                if etype == "midterm": base -= max(0, 10 - sem_offset * 2)
                else:                  base += sem_offset * 1.5
            if stu["archetype"] == "slow_fader" and etype == "endterm":
                base -= sem_offset * 2.5
            if stu["archetype"] == "burnout_risk":
                b_sem = a.get("burnout_sem", 2)
                if semester >= b_sem:
                    drop = 16 if etype == "endterm" else 9
                    base -= drop * _burnout_factor(14, "exam")

            # Y1 adjustment
            if year_of_study == 1:
                base += _y1_adj(stu, semester, year_of_study)

            # Crisis
            if in_crisis:
                ph    = _crisis_phase(16)
                base += a.get("crisis_score_drop", 0) * ph
                if etype == "endterm": base -= 10 * ph

            # Dramatic arc
            arc_week = ENDTERM_WEEK if etype == "endterm" else MIDTERM_WEEK
            base += _arc_mod(stu, semester, arc_week, "score")

            # Noise scaled by volatility
            sigma, _ = _weekly_sigma(tr["volatility"], base_sigma=7.5)
            base     = _noisy(base, sigma, 8, 100)
            marks    = round(ex["max_marks"] * base / 100)
            pct      = round(marks / ex["max_marks"] * 100, 1)

            rows.append((ex["schedule_id"], stu["student_id"], class_id,
                         marks, ex["max_marks"], pct,
                         "P" if pct >= 40 else "F",
                         _score_to_grade(pct), str(result_date)))
    return rows


# ── MOMENTUM UPDATE ───────────────────────────────────────────────────────────
def _update_momentum(cur, class_id, semester):
    """
    After endterm: update each student's momentum.
    Good performance → positive carry-forward.  Bad → small drag.
    Clamped to [-8, +8] so it never dominates.
    """
    results = _fetch_all(cur,
        """SELECT er.student_id, er.score_pct, s.archetype,
                  COALESCE(s.momentum, 0.0) AS momentum
           FROM exam_results er
           JOIN students s ON er.student_id = s.student_id
           JOIN exam_schedule es ON er.schedule_id = es.schedule_id
           WHERE er.class_id=%s AND es.semester=%s AND es.exam_type='endterm'""",
        (class_id, semester))

    baselines = {
        "high_performer": 85, "consistent_avg": 65, "late_bloomer": 58,
        "slow_fader": 63, "crammer": 57, "crisis_student": 55,
        "silent_disengager": 54, "burnout_risk": 75, "social_learner": 57,
        "priority_absent": 59,
    }

    by_stu = {}
    for r in results:
        sid = r["student_id"]
        if sid not in by_stu:
            by_stu[sid] = {"scores": [], "archetype": r["archetype"],
                           "old_mom": r["momentum"]}
        by_stu[sid]["scores"].append(r["score_pct"])

    for sid, d in by_stu.items():
        avg      = sum(d["scores"]) / len(d["scores"])
        baseline = baselines.get(d["archetype"], 62)
        delta    = (avg - baseline) / 10.0
        new_mom  = _clamp(d["old_mom"] + delta * 0.4, -8, 8)
        cur.execute("UPDATE students SET momentum=%s WHERE student_id=%s",
                    (round(new_mom, 3), sid))


# ── PUBLIC: ADVANCE WEEK ──────────────────────────────────────────────────────
def advance_week(seed=None):
    if seed is not None:
        random.seed(seed)

    conn = get_conn()
    conn.autocommit = False
    cur  = conn.cursor()

    try:
        state      = _get_sim_state(cur)
        cur_global = state["current_week"]
        sim_year   = state["sim_year"]
        new_global = cur_global + 1

        if new_global > TOTAL_WEEKS:
            raise ValueError(
                f"Year complete — at week {cur_global}/{TOTAL_WEEKS}. "
                "Use rollback_to_week(0) to reset.")

        sem_week, slot = _global_to_sem_week(new_global)
        is_exam_week   = sem_week in EXAM_WEEKS
        classes        = _get_classes(cur)
        _populate_sem_start_cache(cur, classes, sim_year)

        summary = {"global_week": new_global, "sem_week": sem_week,
                   "semester_slot": slot, "is_exam_week": is_exam_week,
                   "classes": {}}

        for cls in classes:
            class_id  = cls["class_id"]
            year      = cls["year_of_study"]
            odd_sem   = cls["odd_sem"]
            even_sem  = cls["even_sem"]
            semester  = odd_sem if slot == "odd" else even_sem
            sem_start = _sem_start_from_cache(class_id, semester)
            wdate     = _week_monday(sem_start, sem_week)
            cls_p     = _get_class_personality(cls["class_seed"])

            if _week_exists(cur, class_id, semester, sem_week):
                print(f"  [{class_id}] sem {semester} wk {sem_week} — skip")
                continue

            students = _get_students(cur, class_id)
            for stu in students:
                stu["odd_sem"] = odd_sem   # needed for Y1 adjustment

            counts = {}

            if is_exam_week:
                etype = "midterm" if sem_week == MIDTERM_WEEK else "endterm"
                print(f"  [{class_id}] Sem {semester} Wk {sem_week} ({etype.upper()})")
                exams   = _get_exam_schedule(cur, class_id, semester, sem_week)
                results = _build_exam_results(
                    students, exams, class_id, semester,
                    wdate + timedelta(weeks=RESULT_DELAY_WEEKS), year, cls_p)
                if results:
                    cur.executemany(
                        """INSERT IGNORE INTO exam_results
                           (schedule_id, student_id, class_id,
                            marks_obtained, max_marks, score_pct,
                            pass_fail, grade, result_date)
                           VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                        results)
                    counts["exam_results"] = len(results)
                if etype == "endterm":
                    _update_momentum(cur, class_id, semester)
                summary["classes"][class_id] = counts
                continue

            subjects = _get_subjects_for_sem(cur, class_id, semester)

            att = _build_attendance(students, subjects, class_id, semester,
                                    sem_week, wdate, year, cls_p)
            if att:
                cur.executemany(
                    """INSERT IGNORE INTO attendance
                       (student_id, class_id, subject_id, semester, week,
                        week_date, lectures_held, present, absent, late,
                        attendance_pct)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                    att)
                counts["attendance"] = len(att)

            assignments = _get_assignments_due(cur, class_id, semester, sem_week)
            subs = _build_assignment_submissions(
                cur, students, assignments, class_id, semester, sem_week, year, cls_p)
            if subs:
                cur.executemany(
                    """INSERT IGNORE INTO assignment_submissions
                       (assignment_id, student_id, class_id, status,
                        submission_date, latency_hours, marks_obtained,
                        quality_pct, plagiarism_pct)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                    subs)
                counts["assignment_submissions"] = len(subs)

            quizzes = _get_quizzes(cur, class_id, semester, sem_week)
            qzs = _build_quiz_submissions(students, quizzes, class_id, semester,
                                          sem_week, year, cls_p)
            if qzs:
                cur.executemany(
                    """INSERT IGNORE INTO quiz_submissions
                       (quiz_id, student_id, class_id, attempted,
                        attempt_date, marks_obtained, score_pct)
                       VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                    qzs)
                counts["quiz_submissions"] = len(qzs)

            lib = _build_library_visits(students, class_id, semester, sem_week,
                                        wdate, year, cls_p)
            if lib:
                cur.executemany(
                    """INSERT IGNORE INTO library_visits
                       (student_id, class_id, semester, week,
                        week_date, physical_visits)
                       VALUES (%s,%s,%s,%s,%s,%s)""",
                    lib)
                counts["library_visits"] = len(lib)

            summary["classes"][class_id] = counts

        cur.execute(
            "UPDATE sim_state SET current_week=%s, last_updated=NOW() WHERE id=1",
            (new_global,))
        conn.commit()
        print(f"  Week {new_global} (sem wk {sem_week}, {slot}) committed.")

    except Exception as e:
        conn.rollback()
        print(f"  ERROR — rolled back: {e}")
        raise
    finally:
        _sem_start_cache.clear()
        cur.close()
        conn.close()

    return summary


# ── PUBLIC: ROLLBACK ──────────────────────────────────────────────────────────
def rollback_to_week(target_week):
    if target_week < 0:
        raise ValueError("target_week cannot be negative.")

    conn = get_conn()
    conn.autocommit = False
    cur  = conn.cursor()

    try:
        state    = _get_sim_state(cur)
        cur_week = state["current_week"]
        if target_week >= cur_week:
            raise ValueError(f"target_week ({target_week}) must be < current_week ({cur_week}).")

        print(f"  Rolling back {cur_week} → {target_week} ...")
        tsw, _ = _global_to_sem_week(max(target_week,1)) if target_week > 0 else (0,"odd")

        def _del(tbl, cond, params=()):
            cur.execute(f"DELETE FROM {tbl} WHERE {cond}", params)
            return cur.rowcount

        if target_week == 0:
            da  = _del("attendance",            "1=1")
            dl  = _del("library_visits",        "1=1")
            db  = _del("book_borrows",          "1=1")
            cur.execute("DELETE FROM quiz_submissions");       dq = cur.rowcount
            cur.execute("DELETE FROM assignment_submissions"); ds = cur.rowcount
            cur.execute("DELETE FROM exam_results");           de = cur.rowcount
        elif target_week < WEEKS_PER_SEM:
            da = _del("attendance",
                "week > %s OR semester IN (SELECT even_sem FROM classes)", (tsw,))
            dl = _del("library_visits",
                "week > %s OR semester IN (SELECT even_sem FROM classes)", (tsw,))
            db = _del("book_borrows",
                "borrow_week > %s OR semester IN (SELECT even_sem FROM classes)", (tsw,))
            cur.execute("""DELETE qs FROM quiz_submissions qs
                JOIN quiz_definitions qd ON qs.quiz_id=qd.quiz_id
                WHERE qd.scheduled_week > %s
                   OR qd.semester IN (SELECT even_sem FROM classes)""", (tsw,))
            dq = cur.rowcount
            cur.execute("""DELETE sub FROM assignment_submissions sub
                JOIN assignment_definitions def ON sub.assignment_id=def.assignment_id
                WHERE def.due_week > %s
                   OR def.semester IN (SELECT even_sem FROM classes)""", (tsw,))
            ds = cur.rowcount
        else:
            esw = target_week - WEEKS_PER_SEM
            da = _del("attendance",
                "semester IN (SELECT even_sem FROM classes) AND week > %s", (esw,))
            dl = _del("library_visits",
                "semester IN (SELECT even_sem FROM classes) AND week > %s", (esw,))
            db = _del("book_borrows",
                "semester IN (SELECT even_sem FROM classes) AND borrow_week > %s", (esw,))
            cur.execute("""DELETE qs FROM quiz_submissions qs
                JOIN quiz_definitions qd ON qs.quiz_id=qd.quiz_id
                WHERE qd.semester IN (SELECT even_sem FROM classes)
                  AND qd.scheduled_week > %s""", (esw,))
            dq = cur.rowcount
            cur.execute("""DELETE sub FROM assignment_submissions sub
                JOIN assignment_definitions def ON sub.assignment_id=def.assignment_id
                WHERE def.semester IN (SELECT even_sem FROM classes)
                  AND def.due_week > %s""", (esw,))
            ds = cur.rowcount

        # Exam results
        if target_week == 0 or target_week < MIDTERM_WEEK:
            cur.execute("DELETE FROM exam_results"); de = cur.rowcount
        elif target_week < ENDTERM_WEEK:
            cur.execute("""DELETE er FROM exam_results er
                JOIN exam_schedule es ON er.schedule_id=es.schedule_id
                WHERE es.exam_type='endterm'
                   OR es.semester IN (SELECT even_sem FROM classes)""")
            de = cur.rowcount
        elif target_week < WEEKS_PER_SEM + MIDTERM_WEEK:
            cur.execute("""DELETE er FROM exam_results er
                JOIN exam_schedule es ON er.schedule_id=es.schedule_id
                WHERE es.semester IN (SELECT even_sem FROM classes)""")
            de = cur.rowcount
        elif target_week < WEEKS_PER_SEM + ENDTERM_WEEK:
            cur.execute("""DELETE er FROM exam_results er
                JOIN exam_schedule es ON er.schedule_id=es.schedule_id
                WHERE es.semester IN (SELECT even_sem FROM classes)
                  AND es.exam_type='endterm'""")
            de = cur.rowcount
        else:
            de = 0

        # Reset momentum when rolling back past endterm
        if target_week < ENDTERM_WEEK:
            cur.execute("UPDATE students SET momentum=0.0")

        cur.execute(
            "UPDATE sim_state SET current_week=%s, last_updated=NOW() WHERE id=1",
            (target_week,))
        conn.commit()

        result = {"from_week": cur_week, "to_week": target_week,
                  "deleted": {"attendance": da, "assignment_submissions": ds,
                               "quiz_submissions": dq, "library_visits": dl,
                               "book_borrows": db, "exam_results": de}}
        print(f"  Rollback complete to week {target_week}")
        for tbl, n in result["deleted"].items():
            if n: print(f"    {tbl:<28} {n} rows deleted")
        return result

    except Exception as e:
        conn.rollback()
        print(f"  ERROR — nothing changed: {e}")
        raise
    finally:
        _sem_start_cache.clear()
        cur.close()
        conn.close()


# ── PUBLIC: STATUS ────────────────────────────────────────────────────────────
def get_db_status():
    state     = query("SELECT current_week, sim_year FROM sim_state WHERE id=1")[0]
    global_wk = state["current_week"]
    sim_year  = state["sim_year"]
    sem_week, slot = _global_to_sem_week(max(global_wk,1)) if global_wk > 0 else (0,"odd")
    is_exam   = sem_week in EXAM_WEEKS
    classes   = query("SELECT class_id, year_of_study, odd_sem, even_sem FROM classes")
    events, row_counts = [], {}

    for cls in classes:
        cid      = cls["class_id"]
        semester = cls["odd_sem"] if slot == "odd" else cls["even_sem"]

        if sem_week > 0:
            asn_n = query("SELECT COUNT(*) AS n FROM assignment_definitions "
                          "WHERE class_id=%s AND semester=%s AND due_week=%s",
                          (cid, semester, sem_week))[0]["n"]
            qz_n  = query("SELECT COUNT(*) AS n FROM quiz_definitions "
                          "WHERE class_id=%s AND semester=%s AND scheduled_week=%s",
                          (cid, semester, sem_week))[0]["n"]
        else:
            asn_n = qz_n = 0

        ex_n = query("SELECT COUNT(*) AS n FROM exam_schedule "
                     "WHERE class_id=%s AND semester=%s AND scheduled_week=%s",
                     (cid, semester, sem_week))[0]["n"] if is_exam else 0

        if asn_n: events.append(f"{cid} (sem {semester}): {asn_n} assignment(s) due")
        if qz_n:  events.append(f"{cid} (sem {semester}): {qz_n} quiz(zes)")
        if ex_n:  events.append(
            f"{cid} (sem {semester}): "
            f"{'MIDTERM' if sem_week==MIDTERM_WEEK else 'ENDTERM'} EXAM")

        row_counts[cid] = {
            "attendance":             query("SELECT COUNT(*) AS n FROM attendance WHERE class_id=%s",(cid,))[0]["n"],
            "assignment_submissions": query("SELECT COUNT(*) AS n FROM assignment_submissions WHERE class_id=%s",(cid,))[0]["n"],
            "quiz_submissions":       query("SELECT COUNT(*) AS n FROM quiz_submissions WHERE class_id=%s",(cid,))[0]["n"],
            "exam_results":           query("SELECT COUNT(*) AS n FROM exam_results WHERE class_id=%s",(cid,))[0]["n"],
        }

    return {
        "global_week":            global_wk,
        "semester_week":          sem_week,
        "semester_slot":          slot,
        "is_exam_week":           is_exam,
        "weeks_remaining":        TOTAL_WEEKS - global_wk,
        "sim_year":               sim_year,
        "events_at_current_week": events,
        "row_counts_by_class":    row_counts,
    }
