package translator.handlers;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IProject;
import org.eclipse.jdt.core.ICompilationUnit;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jdt.core.IPackageFragment;
import org.eclipse.jdt.core.IPackageFragmentRoot;
import org.eclipse.jdt.core.JavaCore;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

public class TransformHandler extends AbstractHandler {
	public TransformHandler() {
	}

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			IStructuredSelection selection = (IStructuredSelection) HandlerUtil
					.getActiveMenuSelection(event);

			Collection<ICompilationUnit> units = new ArrayList<ICompilationUnit>();
			IJavaProject project = null;

			Iterator iter = selection.iterator();
			while (iter.hasNext()) {
				Object element = iter.next();

				if (element instanceof IJavaProject) {
					project = (IJavaProject) element;
					units.addAll(HandlerHelper.units(project));
				} else if (element instanceof IPackageFragmentRoot) {
					IPackageFragmentRoot pfr = (IPackageFragmentRoot) element;
					project = pfr.getJavaProject();
					units.addAll(HandlerHelper.units(pfr));
				} else if (element instanceof IPackageFragment) {
					IPackageFragment pf = (IPackageFragment) element;
					project = pf.getJavaProject();
					units.addAll(HandlerHelper.units(pf));
				} else if (element instanceof ICompilationUnit) {
					ICompilationUnit cu = (ICompilationUnit) element;
					project = cu.getJavaProject();
					units.addAll(HandlerHelper.units(cu));
				} else if (element instanceof IProject) {
					IProject p = (IProject) element;
					if (p.isOpen() && p.hasNature(JavaCore.NATURE_ID)) {
						project = JavaCore.create(p);
						units.addAll(HandlerHelper.units(project));
					}
				}
			}

			if (project != null && units != null) {
				HandlerHelper.process(project, units);
			} else {
				MessageDialog.openInformation(
						HandlerUtil.getActiveShell(event), "Invalid selection",
						"Please select a Java project, package or source file");
			}
		} catch (Exception e) {
			e.printStackTrace();
			MessageDialog.openError(HandlerUtil.getActiveShell(event),
					"Error processing selection", e.getMessage());
		}

		return null;
	}

}
