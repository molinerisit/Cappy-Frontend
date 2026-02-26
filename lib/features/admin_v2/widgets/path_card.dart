import 'package:flutter/material.dart';
import '../../../widgets/app_network_image.dart';

class PathCard extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final Color accentColor;
  final String country;
  final int moduleCount;
  final int lessonCount;
  final String status; // 'published' | 'draft'
  final VoidCallback onManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onArchive;

  const PathCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.accentColor,
    required this.country,
    required this.moduleCount,
    required this.lessonCount,
    required this.status,
    required this.onManage,
    this.onEdit,
    this.onDuplicate,
    this.onArchive,
  });

  @override
  State<PathCard> createState() => _PathCardState();
}

class _PathCardState extends State<PathCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.3)
                : Colors.grey.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.03),
              blurRadius: _isHovered ? 12 : 6,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onManage,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Image/Color + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image or color indicator
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: widget.imageUrl != null
                            ? AppNetworkImage(
                                imageUrl: widget.imageUrl!,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(8),
                                errorWidget: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: widget.accentColor,
                                  size: 28,
                                ),
                              )
                            : Icon(
                                Icons.kitchen_outlined,
                                color: widget.accentColor,
                                size: 28,
                              ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.status == 'published'
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          border: Border.all(
                            color: widget.status == 'published'
                                ? Colors.green.shade200
                                : Colors.amber.shade200,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.status == 'published'
                                    ? Colors.green.shade600
                                    : Colors.amber.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.status == 'published'
                                  ? 'Publicado'
                                  : 'Borrador',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.status == 'published'
                                    ? Colors.green.shade700
                                    : Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info: Country, Modules, Lessons
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.public_outlined,
                        label: widget.country,
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.account_tree_outlined,
                        label: '${widget.moduleCount} módulos',
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.school_outlined,
                        label: '${widget.lessonCount} lecciones',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(height: 1, color: Colors.grey.shade100),

                  const SizedBox(height: 12),

                  // Footer: Manage button + Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Manage button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onManage,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  'Administrar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Context menu
                      PopupMenuButton<void>(
                        icon: Icon(
                          Icons.more_vert_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) => <PopupMenuEntry<void>>[
                          if (widget.onEdit != null)
                            PopupMenuItem(
                              onTap: widget.onEdit,
                              child: Row(
                                children: const [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          if (widget.onDuplicate != null)
                            PopupMenuItem(
                              onTap: widget.onDuplicate,
                              child: Row(
                                children: const [
                                  Icon(Icons.content_copy_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Duplicar'),
                                ],
                              ),
                            ),
                          if (widget.onEdit != null ||
                              widget.onDuplicate != null)
                            const PopupMenuDivider(),
                          if (widget.onArchive != null)
                            PopupMenuItem(
                              onTap: widget.onArchive,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
                                    size: 16,
                                    color: Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Archivar',
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
