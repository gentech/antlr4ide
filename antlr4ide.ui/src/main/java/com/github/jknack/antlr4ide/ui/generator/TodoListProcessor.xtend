package com.github.jknack.antlr4ide.ui.generator

import org.eclipse.core.resources.IFile
import com.google.inject.Inject
import java.util.regex.Pattern
import org.eclipse.core.resources.IMarker
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import java.util.List
import com.github.jknack.antlr4ide.generator.CodeGeneratorListener
import com.github.jknack.antlr4ide.generator.ToolOptions
import com.github.jknack.antlr4ide.services.GrammarResource
import org.eclipse.xtext.nodemodel.ILeafNode

class TodoListProcessor implements CodeGeneratorListener {

  static val TASK_MARKER = "org.eclipse.core.resources.taskmarker"

  static val TODO = Pattern.compile("(TODO|FIXME)\\s*:.*?\n")

  @Inject
  GrammarResource grammarResource

  override beforeProcess(IFile file, ToolOptions options) {
    file.deleteMarkers(TASK_MARKER, false, IResource.DEPTH_ZERO)
  }

  override afterProcess(IFile file, ToolOptions options) {
    val grammar = grammarResource.grammarFrom(file)

    documentationNodes(grammar).forEach [ comment |
      val matcher = TODO.matcher(comment.text)
      while (matcher.find) {
        val text = matcher.group.trim
        val offset = comment.offset + matcher.start
        val end = offset + text.length
        val priority = if(text.contains("TODO")) IMarker.PRIORITY_NORMAL else IMarker.PRIORITY_HIGH

        val marker = file.createMarker(TASK_MARKER)

        marker.setAttribute(IMarker.PRIORITY, priority)
        marker.setAttribute(IMarker.MESSAGE, text)
        marker.setAttribute(IMarker.LOCATION, "line " + comment.startLine)
        marker.setAttribute(IMarker.CHAR_START, offset)
        marker.setAttribute(IMarker.CHAR_END, end)
        marker.setAttribute(IMarker.USER_EDITABLE, false)
      }
    ]
  }

  private def documentationNodes(EObject object) {
    val node = NodeModelUtils.getNode(object);
    val List<ILeafNode> result = newArrayList()
    if (node != null) {
      for (ILeafNode leafNode : node.getLeafNodes()) {
        if (leafNode.isHidden()) {
          result.add(leafNode)
        }
      }
    }
    return result;
  }
}
