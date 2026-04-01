ENGSCI 773 optimisation assignment - read this first

This folder is an add-on to your team's completed BEM assignment code.
It is not a complete BEM solution.

What to do
1. Copy these files into the folder containing your team's completed code from the previous assignment.
2. Rerun your old checks first, for example your BEM / evaluateTurbine / XFOIL sanity checks.
3. Run testCreateSurrogate.m and make sure it works.
4. Then complete:
   - turbineObj.m
   - optimiseTurbineGivenShape.m
   - optimiseTurbine.m

Files provided here
- createSurrogate.m
- testCreateSurrogate.m

Files you need to complete
- turbineObj.m
- optimiseTurbineGivenShape.m
- optimiseTurbine.m

Important notes
- createSurrogate takes its construction angle range in degrees.
- The returned fx should be called with angles in radians.
- For the core assignment, use wind speeds [4 5 6 7] and weights [0.25 0.45 0.20 0.10].
- Use the RPM rule from the assignment handout:
  * RPM < 0      -> zero contribution
  * 0 <= RPM <= 200 -> full contribution
  * 200 < RPM < 250 -> linearly reduce contribution to zero
  * RPM >= 250   -> zero contribution
- For the core assignment, use one constant airfoil shape across the whole blade and one fixed blade count.

Apple Silicon Mac note
If you are using an Apple Silicon Mac, make sure your separate XFOIL_MAC_STUDENT_PACKAGE is working before you run createSurrogate.
In particular, do not rely on an old Windows-only xfoil.exe setup.
Follow the XFOIL_MAC_STUDENT_PACKAGE README and make sure MATLAB is using that Mac XFOIL setup when you test createSurrogate.
