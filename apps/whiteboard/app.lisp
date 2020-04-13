;imports
(import 'sys/lisp.inc)
(import 'class/lisp.inc)
(import 'gui/lisp.inc)
(import 'apps/math.inc)

(structure 'event 0
	(byte 'close 'max 'min)
	(byte 'clear 'undo 'redo)
	(byte 'grid 'plain 'lines)
	(byte 'radius1 'radius2 'radius3)
	(byte 'pen 'line 'arrow1 'arrow2 'box 'circle 'fbox 'fcircle)
	(byte 'black 'white 'red 'green 'blue 'cyan 'yellow 'magenta)
	(byte 'tblack 'twhite 'tred 'tgreen 'tblue 'tcyan 'tyellow 'tmagenta))

(defun-bind trans (_)
	;transparent colour
	(+ (logand 0xffffff _) 0x60000000))

(defq canvas_width 800 canvas_height 600 min_width 320 min_height 240 eps 0.25 tol 3.0
	radiuss '(2.0 6.0 12.0) stroke_radius (elem 0 radiuss) then (time)
	palette (list argb_black argb_white argb_red argb_green argb_blue argb_cyan argb_yellow argb_magenta)
	palette (cat palette (map trans palette)) undo_stack (list) redo_stack (list)
	stroke_col (elem 0 palette) stroke_mode event_pen commited_strokes (list) in_flight_strokes (list)
	radius_buttons (list) style_buttons (list) ink_buttons (list) mode_buttons (list))

(ui-window window ()
	(ui-title-bar _ "Whiteboard" (0xea19 0xea1b 0xea1a) (const event_close))
	(ui-tool-bar _ ()
		(ui-buttons (0xe970 0xe9fe 0xe99d) (const event_clear))
		(ui-buttons (0xe9a3 0xe976 0xe9d4) (const event_grid) () style_buttons)
		(ui-buttons (0xe979 0xe97d 0xe97b) (const event_radius1) () radius_buttons)
		(ui-buttons (0xe9ec 0xe9d8 0xe917 0xea20 0xe9f6 0xe94b 0xe960 0xe95f) (const event_pen) () mode_buttons))
	(ui-tool-bar _ ('font *env_medium_toolbar_font*)
		(each (lambda (col)
			(push ink_buttons (component-connect (ui-button __ ('ink_color col 'text
				(if (< _ 8) (const (num-to-utf8 0xe982)) (const (num-to-utf8 0xea04)))))
					(+ _ event_black)))) palette))
	(ui-scroll image_scroll (logior scroll_flag_vertical scroll_flag_horizontal)
			('min_width canvas_width 'min_height canvas_height)
		(ui-backdrop backdrop ('color 0xffF8F8FF 'ink_color 0xffADD8E6 'style 1)
			(ui-canvas overlay_canvas canvas_width canvas_height 1)
			(ui-canvas strokes_canvas canvas_width canvas_height 1))))

(defun-bind radio_select (l i)
	;radio select buttons
	(each (lambda (b)
		(def (view-dirty b) 'color (if (= _ i) (const argb_grey14) (const *env_toolbar_col*)))) l) i)

(defun-bind flatten-circle (r s)
	;flatten to circle
	(bind '(x y x1 y1) s)
	(points-stroke-polygons r (const eps) (const join_bevel)
		(list (points-gen-arc x y 0 fp_2pi (vec-length (vec-sub (points x y) (points x1 y1))) (const eps) (points))) (list)))

(defun-bind flatten-box (r s)
	;flatten to box
	(bind '(x y x1 y1) s)
	(points-stroke-polygons r (const eps) (const join_miter)
		(list (points x y x1 y x1 y1 x y1)) (list)))

(defun-bind flatten-fcircle (r s)
	;flatten to filled circle
	(bind '(x y x1 y1) s)
	(list (points-gen-arc x y 0 fp_2pi (vec-length (vec-sub (points x y) (points x1 y1))) (const eps) (points))))

(defun-bind flatten-fbox (r s)
	;flatten to filled box
	(bind '(x y x1 y1) s)
	(list (points x y x1 y x1 y1 x y1)))

(defun-bind flatten-arrow1 (r s)
	;flatten to arrow1
	(points-stroke-polylines r (const eps) (const join_bevel) (const cap_butt) (const cap_arrow) (list s) (list)))

(defun-bind flatten-arrow2 (r s)
	;flatten to arrow2
	(points-stroke-polylines r (const eps) (const join_bevel) (const cap_arrow) (const cap_arrow) (list s) (list)))

(defun-bind flatten-pen (r s)
	;flatten to pen stroke
	(points-stroke-polylines r (const eps) (const join_bevel) (const cap_round) (const cap_round) (list s) (list)))

(defun-bind flatten (r s)
	;flatten a polyline to polygons
	(cond
		((< (length s) 2)
			;a runt so nothing
			'())
		((= 2 (length s))
			;just a point
			(list (points-gen-arc (elem 0 s) (elem 1 s) 0 fp_2pi r (const eps) (points))))
		(t	;is a polyline draw
			(cond
				((= stroke_mode (const event_arrow1)) (flatten-arrow1 r s))
				((= stroke_mode (const event_arrow2)) (flatten-arrow2 r s))
				((= stroke_mode (const event_box)) (flatten-box r s))
				((= stroke_mode (const event_circle)) (flatten-circle r s))
				((= stroke_mode (const event_fbox)) (flatten-fbox r s))
				((= stroke_mode (const event_fcircle)) (flatten-fcircle r s))
				(t	(flatten-pen r s))))))

(defun-bind snapshot ()
	;take a snapshot of the canvas state
	(push undo_stack (cat commited_strokes))
	(clear redo_stack))

(defun-bind undo ()
	;move state from undo to redo stack and restore old state
	(when (/= 0 (length undo_stack))
		(push redo_stack commited_strokes)
		(setq commited_strokes (pop undo_stack))
		(redraw 1 t)) t)

(defun-bind redo ()
	;move state from redo to undo stack and restore old state
	(when (/= 0 (length redo_stack))
		(push undo_stack commited_strokes)
		(setq commited_strokes (pop redo_stack))
		(redraw 1 t)) t)

(defun-bind commit (r s c)
	;commit a stroke to the canvas
	(push commited_strokes (list c (flatten r s))))

(defun-bind fpoly (canvas col mode _)
	;draw a polygon on a canvas
	(canvas-set-color canvas col)
	(canvas-fpoly canvas 0 0 mode _))

(defun-bind redraw (mask &optional f)
	;redraw layer/s with optional timed forced drawing
	(when (or (> (defq now (time)) (+ then 50000)) f)
		(setq then now)
		(when (/= 0 (logand mask 1))
			(canvas-fill strokes_canvas 0)
			(each (lambda ((c s)) (fpoly strokes_canvas c 1 s)) commited_strokes)
			(canvas-swap strokes_canvas))
		(when (/= 0 (logand mask 2))
			(canvas-fill overlay_canvas 0)
			(each (lambda ((r s)) (fpoly overlay_canvas stroke_col 1 (flatten r s))) in_flight_strokes)
			(canvas-swap overlay_canvas))) mask)

(defun-bind main ()
	;ui tree initial setup
	(canvas-set-flags strokes_canvas 1)
	(canvas-set-flags overlay_canvas 1)
	(view-set-size backdrop canvas_width canvas_height)
	(radio_select ink_buttons 0)
	(radio_select mode_buttons 0)
	(radio_select radius_buttons 0)
	(radio_select style_buttons 1)
	(redraw 3 t)
	(gui-add (apply view-change (cat (list window 256 128) (view-pref-size window))))
	(def image_scroll 'min_width min_width 'min_height min_height)
	(defq last_state 'u last_point nil last_mid_point nil)
	;main event loop
	(while (cond
		((= (defq id (get-long (defq msg (mail-read (task-mailbox))) ev_msg_target_id)) event_close)
			nil)
		((= id event_min)
			;min button
			(apply view-change-dirty (cat (list window) (view-get-pos window)(view-pref-size window))))
		((= id event_max)
			;max button
			(def image_scroll 'min_width canvas_width 'min_height canvas_height)
			(apply view-change-dirty (cat (list window) (view-get-pos window)(view-pref-size window)))
			(def image_scroll 'min_width min_width 'min_height min_height))
		((<= event_black id event_tmagenta)
			;ink pot
			(setq stroke_col (elem (radio_select ink_buttons (- id event_black)) palette)))
		((<= event_pen id event_fcircle)
			;draw mode
			(setq stroke_mode (+ (radio_select mode_buttons (- id event_pen)) event_pen)))
		((<= event_radius1 id event_radius3)
			;stroke radius
			(setq stroke_radius (elem (radio_select radius_buttons (- id event_radius1)) radiuss)))
		((<= event_grid id event_lines)
			;styles
			(def (view-dirty backdrop) 'style (radio_select style_buttons (- id event_grid))))
		((= id event_clear)
			;clear
			(snapshot)
			(clear commited_strokes)
			(redraw 1 t))
		((= id event_undo)
			;undo
			(undo))
		((= id event_redo)
			;undo
			(redo))
		((= id (component-get-id overlay_canvas))
			;event for canvas
			(when (= (get-long msg ev_msg_type) ev_type_mouse)
				;mouse event in canvas
				(defq new_point (points (* (get-int msg ev_msg_mouse_rx) 1.0)
					(* (get-int msg ev_msg_mouse_ry) 1.0)))
				(cond
					((/= (get-int msg ev_msg_mouse_buttons) 0)
						;mouse button is down
						(case last_state
							(d	;was down last time, what draw mode ?
								(cond
									((= stroke_mode (const event_pen))
										;pen mode, so extend last stroke ?
										(defq stroke (elem -2 (elem -2 in_flight_strokes))
											mid_vec (vec-sub new_point last_point))
										(when (>= (vec-length-squared mid_vec) (fmul stroke_radius stroke_radius))
											(defq mid_point (vec-add last_point (vec-scale mid_vec 0.5)))
											(points-gen-quadratic
												(elem 0 last_mid_point) (elem 1 last_mid_point)
												(elem 0 last_point) (elem 1 last_point)
												(elem 0 mid_point) (elem 1 mid_point)
												(const eps) stroke)
											(points-filter stroke stroke (const tol))
											(setq last_point new_point last_mid_point mid_point)
											(redraw 2)))
									(t	;a shape mode
										(elem-set -2 (elem -2 in_flight_strokes)
											(points (elem 0 last_point) (elem 1 last_point)
												(elem 0 new_point) (elem 1 new_point)))
										(redraw 2))))
							(u	;was up last time, so start new stroke
								(setq last_state 'd last_point new_point last_mid_point new_point)
								(push in_flight_strokes (list stroke_radius new_point))
								(redraw 2 t))))
					(t	;mouse button is up
						(case last_state
							(d	;was down last time, so last point and commit stroke
								(snapshot)
								(setq last_state 'u)
								(defq stroke (elem -2 (elem -2 in_flight_strokes)))
								(push stroke (elem 0 new_point) (elem 1 new_point))
								(points-filter stroke stroke 0.5)
								(each (lambda ((w s)) (commit w s stroke_col)) in_flight_strokes)
								(clear in_flight_strokes)
								(redraw 3 t))
							(u	;was up last time, so we are hovering
								t))))) t)
		(t (view-event window msg))))
	;close window
	(view-hide window))
