import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/ai_loader/star_painter.dart';
import 'package:ispect/src/features/talker/bloc/ai_chat/ai_chat_bloc.dart';
import 'package:ispect/src/features/talker/core/data/models/chat_message.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<AiChatBloc>(context).add(
        InitChat(
          logs: ISpect.talker.history,
        ),
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CustomPaint(
                painter: AiLoaderPainter(),
                child: const SizedBox(width: 24, height: 24),
              ),
              const Gap(12),
              const Text(
                'AI Chat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                  ),
                  onSubmitted: (message) {
                    _sendMessage(context);
                  },
                ),
              ),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _sendMessage(context);
                },
              ),
            ],
          ),
        ),
        body: BlocConsumer<AiChatBloc, AiChatState>(
          listener: (context, state) {
            if (state is AiChatReceived) {
              _messages.add(state.message);
              Future<void>.delayed(const Duration(milliseconds: 200), () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              });
              // _scrollController.animateTo(
              //   _scrollController.position.maxScrollExtent,
              //   duration: const Duration(milliseconds: 200),
              //   curve: Curves.easeOut,
              // );
            }
          },
          builder: (context, state) => ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              if (message is UserMessage) {
                return _UserMessageWidget(
                  message: message.message,
                  id: message.id,
                );
              } else if (message is AIMessage) {
                return _AIMessageWidget(
                  message: message.message,
                  id: message.id,
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      );

  void _sendMessage(BuildContext context) {
    final now = DateTime.now();
    final message = UserMessage(
      id: _textController.text.hashCode ^ now.hashCode,
      message: _textController.text,
      createdAt: now,
    );
    _messages.add(message);
    _textController.clear();
    BlocProvider.of<AiChatBloc>(context).add(
      SendMessage(
        message,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}

class _AIMessageWidget extends StatelessWidget {
  const _AIMessageWidget({
    required this.message,
    required this.id,
  });
  final int id;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        key: ValueKey(id),
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircleAvatar(
                            maxRadius: 14,
                            child: Text(
                              'AI',
                              style: context.ispectTheme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'ISpect AI',
                          style: context.ispectTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              message,
                              style: context.ispectTheme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class _UserMessageWidget extends StatelessWidget {
  const _UserMessageWidget({
    required this.message,
    required this.id,
  });
  final int id;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        key: ValueKey(id),
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'You',
                          style: context.ispectTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircleAvatar(
                            maxRadius: 14,
                            child: Text(
                              'Y',
                              style: context.ispectTheme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              message,
                              style: context.ispectTheme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
